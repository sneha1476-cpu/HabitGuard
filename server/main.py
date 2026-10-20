from fastapi import FastAPI

app = FastAPI(title="HabitGuard ML Service")

@app.get("/")
def root():
    return {"service": "HabitGuard ML Service", "status": "ready"}

@app.get("/health")
def health():
    return {"status": "ok"}
