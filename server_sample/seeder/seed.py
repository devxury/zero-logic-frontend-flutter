import os
import json
import sys
from pymongo import MongoClient
from pymongo.errors import ConnectionFailure, OperationFailure

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

try:
    from pydantic import ValidationError
    from app.models.ui_contracts import (
        UILayoutContract, 
        UIFragmentContract, 
        UIManifestContract, 
        ThemeContract
    )
except ImportError as e:
    print(f"Advertencia: No se pudieron cargar los contratos Pydantic. ¿Estás ejecutando el script desde la raíz del proyecto? Error: {e}")
    sys.exit(1)

MONGO_URI = os.getenv("MONGO_URI", "mongodb://localhost:27017")
DB_NAME = os.getenv("MONGO_DB_NAME", "dad-autonomous-demo")

VALIDATION_SCHEMAS = {
    "ui_layouts": UILayoutContract,
    "ui_fragments": UIFragmentContract,
    "ui_manifests": UIManifestContract,
    "sys_themes": ThemeContract
}

def seed_database():
    print("🌱 Iniciando motor de Seeding DAD-UI (Strict Mode FAANG)...")
    print(f"🔌 Intentando conectar a MongoDB...")
    
    try:
        client = MongoClient(MONGO_URI, serverSelectionTimeoutMS=5000)
        client.admin.command('ping')
        print("Conexión exitosa a la base de datos.")
    except ConnectionFailure:
        print("ERROR FATAL: No se pudo conectar a MongoDB.")
        print("Verifica que tu MONGO_URI sea correcto y tu IP esté permitida en MongoDB Atlas.")
        sys.exit(1)

    db = client[DB_NAME]
    
    current_dir = os.path.dirname(os.path.abspath(__file__))
    seeds_dir = os.path.join(current_dir, 'seeds')
    
    if not os.path.exists(seeds_dir):
        print(f"ERROR: El directorio {seeds_dir} no existe.")
        print("Crea la carpeta 'seeds/' junto a este script y añade los archivos JSON.")
        sys.exit(1)

    archivos_procesados = 0

    for filename in os.listdir(seeds_dir):
        if filename.endswith('.json'):
            collection_name = filename.replace('.json', '')
            filepath = os.path.join(seeds_dir, filename)
            
            try:
                with open(filepath, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    
                if data:
                    schema_model = VALIDATION_SCHEMAS.get(collection_name)
                    if schema_model:
                        try:
                            if isinstance(data, list):
                                data = [schema_model(**item).model_dump() for item in data]
                            else:
                                data = schema_model(**data).model_dump()
                        except ValidationError as ve:
                            print(f"\nERROR DE CONTRATO EN '{filename}':")
                            print("El JSON no cumple con la arquitectura 80/20. ¿Cometiste un error tipográfico?")
                            print(ve)
                            print("Saltando archivo por seguridad...\n")
                            continue

                    db[collection_name].drop()
                    
                    if isinstance(data, list):
                        db[collection_name].insert_many(data)
                        print(f"Colección '{collection_name}' reconstruida ({len(data)} documentos).")
                    elif isinstance(data, dict):
                        db[collection_name].insert_one(data)
                        print(f"Colección '{collection_name}' reconstruida (1 documento).")
                    
                    archivos_procesados += 1
                else:
                    print(f"El archivo {filename} está vacío, ignorando.")
                    
            except json.JSONDecodeError as e:
                print(f"ERROR de Sintaxis en {filename}: JSON inválido. Detalles: {e}")
            except OperationFailure as e:
                print(f"ERROR de Permisos en MongoDB al escribir {collection_name}: {e}")
            except Exception as e:
                print(f"ERROR inesperado procesando {filename}: {e}")

    if archivos_procesados > 0:
        print("\n¡Base de datos inicializada y validada exitosamente!")
    else:
        print("\nNo se procesó ningún archivo JSON de manera exitosa.")

if __name__ == "__main__":
    seed_database()