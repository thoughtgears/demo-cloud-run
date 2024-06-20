from google.cloud import firestore
from pydantic import ValidationError
from typing import List, Optional
import hashlib
from datetime import datetime, timezone

from .model import AddressModel


class Firestore:
    def __init__(self, project_id: str):
        self._project_id = project_id
        self._db = firestore.Client(project=project_id)
        self._collection = self._db.collection("network-addresses")

    @staticmethod
    def _generate_id(input_string: str) -> str:
        return hashlib.sha256(input_string.encode()).hexdigest()

    def add(self, address: AddressModel) -> None:
        address.id = self._generate_id(f"{address.project_id}-{address.network}")
        now = datetime.now(timezone.utc)

        doc_ref = self._collection.document(address.id)
        doc = doc_ref.get()

        if doc.exists:
            existing_data = doc.to_dict()
            try:
                existing_address = AddressModel(**existing_data)
                # Extend the existing subnetworks with the new ones
                existing_subnetworks = {subnetwork.network_cidr: subnetwork for subnetwork in existing_address.subnetworks}
                for subnetwork in address.subnetworks:
                    existing_subnetworks[subnetwork.network_cidr] = subnetwork
                address.subnetworks = list(existing_subnetworks.values())
                address.created_at = existing_address.created_at  # Preserve the original created_at
            except ValidationError as e:
                print(f"Invalid data for AddressModel: {e}")
            address.updated_at = now  # Update the updated_at time
        else:
            address.created_at = now  # Set created_at for new document
            address.updated_at = now  # Set updated_at for new document

        address_dict = address.dict()
        doc_ref.set(address_dict)

    def list(self, network_cidr: Optional[str] = None) -> List[AddressModel]:
        addresses = []
        if network_cidr is None:
            # Fetch all documents if network_cidr is None
            docs = self._collection.stream()
        else:
            # Fetch documents with the specified network_cidr
            docs = self._collection.stream()

        for doc in docs:
            data = doc.to_dict()
            try:
                # Validate and create an AddressModel instance
                address = AddressModel(**data)
                if network_cidr is None:
                    # If network_cidr is None, add all documents
                    addresses.append(address)
                else:
                    # Filter subnetworks that match the network_cidr
                    filtered_subnetworks = [subnetwork for subnetwork in address.subnetworks if subnetwork.network_cidr == network_cidr]
                    if filtered_subnetworks:
                        # If there are matching subnetworks, update the address model
                        address.subnetworks = filtered_subnetworks
                        addresses.append(address)
            except ValidationError as e:
                print(f"Invalid data for AddressModel: {e}")
        return addresses

    def delete(self, document_id: str) -> None:
        doc_ref = self._collection.document(document_id)
        if not doc_ref.get().exists:
            raise ValueError(f"Document with ID {document_id} does not exist")
        doc_ref.delete()
