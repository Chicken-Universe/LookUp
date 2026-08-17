import os
import uvicorn
from fastapi import FastAPI, HTTPException
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

try:
    from .agent import run_lookup_agent
except ImportError:
    from agent import run_lookup_agent

app = FastAPI(title="LookUp - Astrophotography AI Platform")
server_instance = None

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class ShootingRequest(BaseModel):
    your_location: str = Field(..., json_schema_extra={"example": "Malang"})
    country: str = Field(..., json_schema_extra={"example": "Indonesia"})
    radius: float = Field(..., json_schema_extra={"example": 25.0})
    shooting_purpose: str = Field(..., json_schema_extra={"example": "Static Photo"})
    camera_gear: str = Field(..., json_schema_extra={"example": "Sony A7 III"})

@app.post("/api/discover")
async def discover_spots(payload: ShootingRequest):
    try:
        result = run_lookup_agent(
            your_location=payload.your_location,
            country=payload.country,
            radius=payload.radius,
            shooting_purpose=payload.shooting_purpose,
            camera_gear=payload.camera_gear
        )
        return {"status": "success", "data": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/shutdown")
async def shutdown_server():
    global server_instance
    if server_instance is not None:
        server_instance.should_exit = True
        await server_instance.shutdown()
    return {"status": "success", "message": "AI engine is shutting down."}

# Path to Frontend SPA
frontend_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "../frontend"))
app.mount("/", StaticFiles(directory=frontend_path, html=True), name="frontend")

if __name__ == "__main__":
    config = uvicorn.Config("main:app", host="127.0.0.1", port=8000, reload=False, log_level="info")
    server_instance = uvicorn.Server(config)
    try:
        server_instance.run()
    except KeyboardInterrupt:
        print("\nAI engine stopped by user.")
    finally:
        print("LookUp server closed.")