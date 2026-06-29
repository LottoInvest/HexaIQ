from fastapi import FastAPI

from .question_engine.router import router as question_engine_router

app = FastAPI(title="HexaIQ Backend Mock")
app.include_router(question_engine_router)


@app.get("/api/v1/health")
def health() -> dict[str, bool]:
    return {"ok": True}
