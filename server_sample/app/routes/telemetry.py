from fastapi import APIRouter, Request, BackgroundTasks
from app.core.database import get_db
from typing import List
from pydantic import BaseModel

router = APIRouter()

class TelemetryLog(BaseModel):
    trace_id: str
    status: str
    component_id: str = "unknown"
    error_stack: str = ""
    platform: str

async def save_logs_to_db(logs: List[dict]):
    db = get_db()
    if logs:
        await db.sys_telemetry.insert_many(logs)
        print(f"[Telemetry] {len(logs)} logs guardados en frío.")

@router.post("/v1/telemetry/batch")
async def receive_telemetry_batch(logs: List[TelemetryLog], background_tasks: BackgroundTasks):
    """
    El Frontend (Flutter) envía esto cada 2 minutos en segundo plano.
    Usamos BackgroundTasks de FastAPI para responder 202 Accepted al instante 
    y guardar en MongoDB de forma asíncrona (Cero lag).
    """
    log_dicts = [log.model_dump() for log in logs]
    
    background_tasks.add_task(save_logs_to_db, log_dicts)
    
    return {"status": "accepted", "received": len(logs)}