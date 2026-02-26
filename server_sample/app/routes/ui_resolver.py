from fastapi import APIRouter, Request, Query
from app.core.database import get_db
import uuid

router = APIRouter()

@router.get("/v1/sync/boot")
async def boot_ui_engine(platform: str = Query("web")):
    db = get_db()
    fragments = await db.ui_fragments.find({"platforms": platform}, {"_id": 0}).to_list(length=500)
    layouts = await db.ui_layouts.find({}, {"_id": 0}).to_list(length=100)
    manifests = await db.ui_manifests.find({}, {"_id": 0}).to_list(length=200)
    themes = await db.sys_themes.find({}, {"_id": 0}).to_list(length=10)

    return {
        "sys": {"trace_id": f"boot-{uuid.uuid4().hex[:8]}", "server_version": "2.0.0"},
        "topology": {"themes": themes, "layouts": layouts, "fragments": fragments, "manifests": manifests}
    }

@router.post("/v1/data/hydrate")
async def hydrate_view_model(request: Request):
    body = await request.json()
    path = body.get("path")
    context = body.get("context", {})
    role = context.get("role", "user") 
    user_id = context.get("user_id")

    db = get_db()
    trace_id = f"req-{uuid.uuid4().hex[:8]}"
    
    manifest = await db.ui_manifests.find_one({"path": path, "role": role})
    view_model = {}

    if manifest and "data_resolvers" in manifest:
        for resolver in manifest["data_resolvers"]:
            target = resolver["target_variable"]
            collection = resolver["collection"]
            operation = resolver["operation"]
            
            query = resolver.get("query", {})
            final_query = {}
            for k, v in query.items():
                if v == "$context.user_id":
                    final_query[k] = user_id
                else:
                    final_query[k] = v


            if operation == "count":
                view_model[target] = await db[collection].count_documents(final_query)
            
            elif operation == "find_one":
                doc = await db[collection].find_one(final_query, sort=[("_id", -1)])
                if doc:
                    doc["_id"] = str(doc["_id"]) 
                    field = resolver.get("field")
                    view_model[target] = doc.get(field) if field else doc
                else:
                    view_model[target] = "N/A"

            elif operation == "find":
                cursor = db[collection].find(final_query)
                results = await cursor.to_list(length=100) 
                
                clean_results = []
                for doc in results:
                    doc["_id"] = str(doc["_id"]) 
                    clean_results.append(doc)
                
                view_model[target] = clean_results

    return {
        "trace_id": trace_id,
        "view_model": view_model
    }