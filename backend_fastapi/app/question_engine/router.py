from fastapi import APIRouter

from .engine import QuestionEngine
from .schemas import GenerateBatchRequest, GenerateBatchResponse, GenerateRequest, QuestionDto

router = APIRouter(prefix="/api/v1/question-engine", tags=["question-engine"])
engine = QuestionEngine()


@router.post("/generate", response_model=QuestionDto)
def generate_question(request: GenerateRequest) -> QuestionDto:
    return engine.generate(
        profile_id=request.profileId,
        domain=request.domain,
        type_code=request.typeCode,
        age_group=request.ageGroup,
        level=request.level,
        seed=request.seed,
    )


@router.post("/generate-batch", response_model=GenerateBatchResponse)
def generate_batch(request: GenerateBatchRequest) -> GenerateBatchResponse:
    return GenerateBatchResponse(
        questions=engine.generate_batch(
            profile_id=request.profileId,
            domain=request.domain,
            age_group=request.ageGroup,
            level=request.level,
            count=request.count,
        )
    )
