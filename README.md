# Demo of Cloud Run capabilities

This repository contains a simple demo of the capabilities of Cloud Run. It will showcase how to deploy applications to Cloud Run, setup Private Service
Connect (PSC) and how to connect private Cloud Run instances using this PSC. The applications are some simple APIs and a frontend that consumes these APIs.
There are two applications, one IPAM and one Service Discovery to also showcase how to use service discovery in Cloud Run.
It will also showcase how to trigger on EventArc within the APIs to trigger a Cloud Run instance to do something based on an event.

## IPAM and Service Discovery

The IPAM application is just to showcase how we can use a Cloud Run instance to manage IP addresses in networks to allow for non overlapping IP addresses. The
Service Discovery application is to showcase how we can use a Cloud Run instance to manage service discovery in a network.

## Setup

All the things that is done with GitHub workflows is also possible through the [Makefile](Makefile). The Makefile is setup to be able to create the
infrastructure and deploy the applications.

### Prerequisites

- [gcloud](https://cloud.google.com/sdk/docs/install)
- [docker](https://docs.docker.com/get-docker/)
- [docker-compose](https://docs.docker.com/compose/install/)
- [terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)

### Setup the environment

To setup the environment you need to create a `.env` file in the root of the repository with the following content:

```bash
GCP_PROJECT_ID=my-project-id
GCP_REGION=my-region
GCP_ORGANIZATION_ID=my-organization-id
```

## Running docker-compose

To run the applications locally you can use `docker-compose` to start the applications. To do this you can run the following command `docker compose up`, this
will require the`.env` file to be present, it maps the applications to the python image to allow for hot reloading of the applications.

The compose file will also create a firebase emulator with firestore enabled to allow for local testing of the applications. The firebase emulator will be
available on `localhost:8080` and the UI will be available on `localhost:4000`.

## Proxy to Cloud Run

To proxy to Cloud Run you can use the `gcloud run serivce proxy` command. This application is a simple application that will proxy requests to Cloud Run. To run
the proxy you can run the following command and it will create a proxy on `localhost:8080`:

```bash
gcloud run services proxy service-name --project your-project-id --region your-region
```

## Deploying the applications

### Local

To deploy the applications locally you can use the `Makefile` to deploy the applications. To deploy the applications you can run the following command:

```bash
make all
```

This will deploy infrastructure with terraform and update the applications to Cloud Run.  
To individually deploy the applications you can run the following commands:

```bash
make infra
make backend
make frontend
make discovery
make ipam
```

### Cloud build

All files have a cloud build file and terraform sets up the cloud build triggers with a connected repo. It will also initially deploy the services to Cloud Run
before cloud run can trigger installations.