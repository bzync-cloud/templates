import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()
app.add_middleware(CORSMiddleware, allow_origins=os.getenv("CORS_ORIGINS", "*").split(","), allow_methods=["*"], allow_headers=["*"])

@app.get("/")
def root():
    return {"message": "FastAPI backend running"}

@app.get("/health")
def health():
    return {"status": "ok"}
