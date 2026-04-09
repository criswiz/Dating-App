import os
import logging
import time
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from app.api import auth, profiles, matches, chat, safety, ai
from app.core.config import CORS_ALLOW_ORIGINS, UPLOADS_DIR
import app.models.user  # noqa: F401
import app.models.social  # noqa: F401

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s %(message)s",
)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Dating App API",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=CORS_ALLOW_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.middleware("http")
async def log_requests(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    logger.info(
        "%s %s status=%s duration=%.4fs",
        request.method,
        request.url.path,
        response.status_code,
        process_time,
    )
    return response


# Serve uploaded photos
os.makedirs(UPLOADS_DIR, exist_ok=True)
app.mount("/static/uploads", StaticFiles(directory=UPLOADS_DIR), name="uploads")

app.include_router(auth.router, prefix="/auth", tags=["auth"])
app.include_router(profiles.router, prefix="/profiles", tags=["profiles"])
app.include_router(matches.router, prefix="/matches", tags=["matches"])
app.include_router(chat.router, prefix="/chat", tags=["chat"])
app.include_router(safety.router, prefix="/safety", tags=["safety"])
app.include_router(ai.router, prefix="/ai", tags=["ai"])


@app.get("/")
def root():
    return {"status": "ok", "message": "Dating App API"}


@app.get("/health")
def health():
    return {"status": "healthy"}
