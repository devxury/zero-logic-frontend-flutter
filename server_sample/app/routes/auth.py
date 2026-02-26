from fastapi import APIRouter, Request, HTTPException
from passlib.context import CryptContext
from app.core.database import get_db
import uuid

router = APIRouter()
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

@router.post("/v1/auth/register")
async def register(request: Request):
    data = await request.json()
    db = get_db()
    
    if await db.biz_users.find_one({"email": data.get("email")}):
        raise HTTPException(status_code=400, detail="El usuario ya existe")
        
    user_id = str(uuid.uuid4())
    
    raw_password = str(data.get("password"))[:70] 
    hashed_password = pwd_context.hash(raw_password)
    
    new_user = {
        "user_id": user_id,
        "name": data.get("name", "Operador"),
        "email": data.get("email"),
        "password": hashed_password,
        "status": "Verified",
        "joined_date": "Hoy"
    }
    await db.biz_users.insert_one(new_user)
    
    return {
        "token": f"jwt_{user_id}",
        "user_id": user_id,
        "context": {"role": "user", "name": new_user["name"], "email": new_user["email"], "user_id": user_id}
    }

@router.post("/v1/auth/login")
async def login(request: Request):
    data = await request.json()
    db = get_db()
    
    user = await db.biz_users.find_one({"email": data.get("email")})
    if not user or not pwd_context.verify(data.get("password"), user["password"]):
        raise HTTPException(status_code=401, detail="Credenciales inválidas")
        
    return {
        "token": f"jwt_{user['user_id']}",
        "user_id": user["user_id"],
        "context": {"role": "user", "name": user["name"], "email": user["email"], "user_id": user["user_id"]}
    }