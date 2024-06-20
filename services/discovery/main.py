from fastapi import FastAPI
from router import router

app = FastAPI()
app.include_router(router)

if __name__ == "__main__":
    import uvicorn

    print("Starting discovery service...")
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
