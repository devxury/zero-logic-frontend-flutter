from fastapi import FastAPI, WebSocket 
from fastapi.middleware.cors import CORSMiddleware
from app.core.database import connect_to_mongo, close_mongo_connection
from app.routes import ui_resolver, api_actions, telemetry, auth 

app = FastAPI(title="NEXUS DAD-UI Backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"], 
    allow_headers=["*"], 
)

@app.on_event("startup")
async def startup_event():
    await connect_to_mongo()

@app.on_event("shutdown")
async def shutdown_event():
    await close_mongo_connection()

# Rutas
app.include_router(ui_resolver.router)
app.include_router(api_actions.router)
app.include_router(telemetry.router)
app.include_router(auth.router) 

@app.get("/")
def read_root():
    return {"status": "DeepCore BFF is Online"}

@app.websocket("/v1/sync")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    try:
        while True:
            await websocket.receive_text()
    except Exception:
        pass