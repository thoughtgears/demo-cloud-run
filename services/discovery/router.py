from fastapi import APIRouter, HTTPException
from database import Firestore, ServiceModel
import os

gcp_project_id = os.getenv("GCP_PROJECT_ID")
if not gcp_project_id:
    raise ValueError("GCP_PROJECT_ID environment variable is not set")

router = APIRouter()
db = Firestore(project_id=gcp_project_id)


@router.post("/services", response_model=ServiceModel)
async def create_service(service: ServiceModel):
    try:
        created_service = db.create(service)
        return created_service
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/services", response_model=list[ServiceModel])
async def list_services():
    try:
        services = db.list()
        return services
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))


@router.get("/services/{service_name}", response_model=ServiceModel)
async def get_service(service_name: str):
    try:
        service = db.get(service_name)
        return service
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))


@router.put("/services/{service_name}", response_model=ServiceModel)
async def update_service(service_name: str, update_data: dict):
    try:
        updated_service = db.update(service_name, update_data)
        return updated_service
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.delete("/services/{service_name}")
async def delete_service(service_name: str):
    try:
        db.delete(service_name)
        return {"message": "service deleted successfully"}
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
