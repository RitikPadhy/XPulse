# XPulse — Backend

FastAPI service. Minimal scaffold; we add pieces one at a time.

## Run

```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -e .
uvicorn main:app --reload
```

Server boots on `:8000`.

```bash
curl localhost:8000/healthz
# → {"status":"ok"}
```

Swagger UI: `localhost:8000/docs`.
