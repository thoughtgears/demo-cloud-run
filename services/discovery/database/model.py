from typing import Optional
from datetime import datetime
from pydantic import BaseModel, ValidationError


class ServiceModel(BaseModel):
    id: Optional[str] = None
    name: str
    description: Optional[str] = None
    url: str = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    class Config:
        # Optional settings for additional validation or customizations
        arbitrary_types_allowed = True
