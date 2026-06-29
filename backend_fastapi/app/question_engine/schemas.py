from __future__ import annotations

from typing import Any, Literal

try:
    from pydantic import BaseModel, Field
except ModuleNotFoundError:
    def Field(default=None, default_factory=None, **_: Any):
        if default_factory is not None:
            return default_factory()
        return default

    class BaseModel:
        def __init__(self, **kwargs: Any) -> None:
            for name, value in kwargs.items():
                setattr(self, name, value)

        def dict(self) -> dict[str, Any]:
            return {
                key: _serialize(value)
                for key, value in self.__dict__.items()
                if not key.startswith("_")
            }

        def model_dump(self) -> dict[str, Any]:
            return self.dict()


    def _serialize(value: Any) -> Any:
        if isinstance(value, BaseModel):
            return value.dict()
        if isinstance(value, list):
            return [_serialize(item) for item in value]
        return value

Domain = Literal["numerical", "spatial", "logical", "verbal", "memory", "pattern"]


class ChoiceDto(BaseModel):
    key: str
    text: str


class MetadataDto(BaseModel):
    rule: str
    difficultyFactors: list[str] = Field(default_factory=list)
    version: str = "v0.1.0"


class QuestionDto(BaseModel):
    id: str
    domain: Domain
    typeCode: str
    level: int = Field(ge=1, le=10)
    ageGroup: str
    questionText: str
    choices: list[ChoiceDto]
    answerKey: str
    explanation: str
    seed: int
    estimatedTimeSec: int
    metadata: MetadataDto


class GenerateRequest(BaseModel):
    profileId: str
    domain: Domain
    typeCode: str = "NR01"
    ageGroup: str = "grade5_6"
    level: int = 5
    seed: int | None = None


class GenerateBatchRequest(BaseModel):
    profileId: str
    domain: Domain = "numerical"
    ageGroup: str = "grade5_6"
    level: int = 5
    count: int = Field(default=30, ge=1, le=240)


class GenerateBatchResponse(BaseModel):
    questions: list[QuestionDto]
