from google.cloud import resourcemanager_v3, compute_v1
from typing import List, Set
from .model import SubnetworkModel, AddressModel
from ipaddress import ip_network


class Search:
    def __init__(self, organization_id: str):
        self._organization_id = organization_id
        self._projects_client = resourcemanager_v3.ProjectsClient()
        self._folders_client = resourcemanager_v3.FoldersClient()
        self._network_client = compute_v1.NetworksClient()
        self._subnetworks_client = compute_v1.SubnetworksClient()

    def list_projects(self) -> List[str]:
        project_set = set()
        self._list_projects_in_folders(f"organizations/{self._organization_id}", project_set)
        return list(project_set)

    def _list_projects_in_folders(self, parent: str, project_set: Set[str]):
        folders_request = resourcemanager_v3.ListFoldersRequest(parent=parent)
        folders_response = self._folders_client.list_folders(request=folders_request)
        for folder in folders_response.folders:
            self._list_projects_in_folder(folder.name, project_set)
            self._list_projects_in_folders(folder.name, project_set)
        self._list_projects_in_folder(parent, project_set)

    def _list_projects_in_folder(self, parent: str, project_set: Set[str]):
        projects_request = resourcemanager_v3.ListProjectsRequest(parent=parent)
        projects_response = self._projects_client.list_projects(request=projects_request)
        for project in projects_response:
            project_set.add(project.project_id)

    def networks(self, project_id: str, cidr_filter: str = None) -> List[AddressModel]:
        networks = []
        request = compute_v1.ListNetworksRequest(project=project_id)
        response = self._network_client.list(request=request)
        for network in response:
            regions = set()
            if network.subnetworks:
                for subnetwork_url in network.subnetworks:
                    # Extract region from subnetwork URL
                    region = subnetwork_url.split("/regions/")[1].split("/")[0]
                    regions.add(region)
            subnetworks = self.list_subnetworks(project_id, network.self_link, regions, cidr_filter)
            networks.append(
                AddressModel(
                    project_id=project_id,
                    network=network.name,
                    subnetworks=subnetworks,
                )
            )
        return networks

    def list_subnetworks(self, project_id: str, network: str, regions: Set[str], cidr_filter: str) -> List[SubnetworkModel]:
        subnetworks = []
        for region in regions:
            request = compute_v1.ListSubnetworksRequest(
                project=project_id,
                region=region,
                filter=f'network="{network}"',
            )
            response = self._subnetworks_client.list(request=request)
            for subnetwork in response:
                if cidr_filter:
                    try:
                        if ip_network(subnetwork.ip_cidr_range).subnet_of(ip_network(cidr_filter)):
                            subnetworks.append(SubnetworkModel(name=subnetwork.name, network_cidr=subnetwork.ip_cidr_range, region=region))
                    except ValueError:
                        pass

                else:
                    subnetworks.append(SubnetworkModel(name=subnetwork.name, network_cidr=subnetwork.ip_cidr_range, region=region))

            # for subnetwork in response:
            #     subnetworks.append(SubnetworkModel(name=subnetwork.name, network_cidr=subnetwork.ip_cidr_range, region=region))
        return subnetworks
