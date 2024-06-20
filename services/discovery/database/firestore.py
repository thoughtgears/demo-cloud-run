from google.cloud import firestore
from pydantic import ValidationError
from datetime import datetime, timezone
from typing import List

import hashlib

from .model import ServiceModel


class Firestore:
    def __init__(self, project_id: str):
        self._project_id = project_id
        self._db = firestore.Client(project=project_id)
        self._collection = self._db.collection("services")

    @staticmethod
    def _generate_id(input_string: str) -> str:
        return hashlib.sha256(input_string.encode()).hexdigest()

    def get(self, service_name: str) -> ServiceModel:
        document_id = self._generate_id(service_name)

        doc = self._collection.document(document_id).get()
        if not doc.exists:
            raise ValueError(f"document with ID {document_id} does not exist")

        data = doc.to_dict()

        try:
            service = ServiceModel(**data)
        except ValidationError as e:
            raise ValueError(f"invalid data for service: {e}")

        return service

    def list(self) -> List[ServiceModel]:
        docs = self._collection.stream()
        services = []
        for doc in docs:
            data = doc.to_dict()
            try:
                service = ServiceModel(**data)
                services.append(service)
            except ValidationError as e:
                print(f"invalid data for ServiceModel: {e}")
        return services

    def create(self, service: ServiceModel) -> ServiceModel:
        current_time = datetime.now(timezone.utc)

        service.id = self._generate_id(service.name)
        service.created_at = current_time
        service.updated_at = current_time

        self._collection.document(service.id).set(service.dict())

        return service

    def update(self, service_name: str, update_data: dict) -> ServiceModel:
        document_id = self._generate_id(service_name)

        doc_ref = self._collection.document(document_id)
        doc = doc_ref.get()
        if not doc.exists:
            raise ValueError(f"document with ID {document_id} does not exist")

        update_data["updated_at"] = datetime.now(timezone.utc)
        doc_ref.update(update_data)

        updated_doc = doc_ref.get().to_dict()
        try:
            updated_service = ServiceModel(**updated_doc)
        except ValidationError as e:
            raise ValueError(f"invalid data for ServiceModel: {e}")

        return updated_service

    def delete(self, service_name: str) -> None:
        document_id = self._generate_id(service_name)

        doc_ref = self._collection.document(document_id)
        if not doc_ref.get().exists:
            raise ValueError(f"Document with ID {document_id} does not exist")

        doc_ref.delete()
