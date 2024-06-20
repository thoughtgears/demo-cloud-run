from typing import Optional
from datetime import datetime
from pydantic import BaseModel


class SubnetworkModel(BaseModel):
    name: str
    network_cidr: str
    region: str


class AddressModel(BaseModel):
    id: Optional[str] = None
    project_id: str
    network: str
    subnetworks: list[SubnetworkModel]
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    class Config:
        # Optional settings for additional validation or customizations
        arbitrary_types_allowed = True
