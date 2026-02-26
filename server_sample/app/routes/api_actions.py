from fastapi import APIRouter, Request 
from pydantic import BaseModel
from app.core.database import get_db

router = APIRouter()

class MetricCreate(BaseModel):
    metric_type: str 
    value: str    
    node_id: str    

@router.post("/v1/metrics/ingest")
async def ingest_metric_action(metric: MetricCreate):
    db = get_db()
    
    await db.biz_metrics.insert_one(metric.model_dump())
    
    return [
        {
            "type": "store.set_variable",
            "payload": {
                "key": "ctx.cpu_load",
                "value": metric.value
            }
        },
        {
            "type": "ui.toast",
            "payload": {
                "message": f"Métrica actualizada: {metric.node_id} -> {metric.value}"
            }
        }
    ]

@router.post("/v1/chat/send")
async def send_message(request: Request):
    data = await request.json()
    db = get_db()
    
    new_msg = {
        "receiver_id": data.get("receiver_id"),
        "sender": data.get("sender_name", "Desconocido"),
        "text": data.get("text")
    }
    await db.biz_messages.insert_one(new_msg)
    
    return [
        {
            "type": "nav.overlay_close",
            "payload": {"id": "msg_modal"}
        },
        {
            "type": "ui.toast",
            "payload": {"message": "Mensaje encriptado y enviado exitosamente."}
        }
    ]