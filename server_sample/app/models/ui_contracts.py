from pydantic import BaseModel, Field
from typing import Dict, List, Optional, Any

class UIFragmentContract(BaseModel):
    id: str
    type: str = Field(..., description="Ej: organism.metric_grid")
    platforms: List[str] = Field(default=["web", "ios", "android", "macos"]) 
    props: Dict[str, Any] = Field(default_factory=dict)

class UILayoutContract(BaseModel):
    id: str
    regions: List[str] = Field(..., description="Ej: ['sidebar', 'main_content']")
    props: Dict[str, Any] = Field(default_factory=dict)

class ResolverContract(BaseModel):
    target_variable: str
    collection: str
    operation: str 
    query: Dict[str, Any] = Field(default_factory=dict)
    field: Optional[str] = None 

class UIManifestContract(BaseModel):
    path: str
    role: str
    layout_id: str
    slots: Dict[str, List[str]] = Field(..., description="Mapea regiones con IDs de fragmentos")
    data_resolvers: List[ResolverContract] = Field(default_factory=list)

class ThemeContract(BaseModel):
    id: str
    semantics: Dict[str, Any] = Field(..., description="Ej: {'semantic.critical': '#FF0000'}")