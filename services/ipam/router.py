from fastapi import APIRouter, HTTPException, Query
from database import Firestore, AddressModel, Search
from typing import List
import os

gcp_project_id = os.getenv("GCP_PROJECT_ID")
if not gcp_project_id:
    raise ValueError("GCP_PROJECT_ID environment variable is not set")

gcp_organization_id = os.getenv("GCP_ORGANIZATION_ID")
if not gcp_organization_id:
    raise ValueError("GCP_ORGANIZATION_ID environment variable is not set")

router = APIRouter()
db = Firestore(project_id=gcp_project_id)
search = Search(organization_id=gcp_organization_id)


@router.get("/addresses", response_model=List[AddressModel])
async def list_services(network_cidr: str = Query(None)):
    try:
        networks = db.list(network_cidr=network_cidr)
        if not networks:
            projects = search.list_projects()
            for project_id in projects:
                response = search.networks(project_id=project_id, cidr_filter=network_cidr)
                for address in response:
                    db.add(address)
                networks.extend(response)
        return networks
    except ValueError as e:
        print("Error:", e)
        raise HTTPException(status_code=404, detail=str(e))


@router.delete("/addresses/{document_id}")
async def delete_service(document_id: str):
    try:
        db.delete(document_id)
        return {"message": "address record deleted successfully"}
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
