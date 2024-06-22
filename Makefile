ifneq (,$(wildcard ./.env))
    include .env
    export
endif

GIT_SHA := $(shell git rev-parse --short HEAD)
DOCKER_REPO := "$(GCP_REGION)-docker.pkg.dev/$(GCP_PROJECT_ID)"

SERVICES := discovery ipam

.PHONY: spacelift backend discovery ipam infra all

spacelift:
	cd resources/cloud_build/spacelift && \
	docker build -t gcr.io/$(GCP_PROJECT_ID)/spacelift . && \
	docker run --rm -it gcr.io/$(GCP_PROJECT_ID)/spacelift --api-key $(SPACELIFT_API_KEY) --key-id $(SPACELIFT_API_KEY_ID) --stack-id $(SPACELIFT_STACK_ID) --url $(SPACELIFT_API_URL)

all: infra backend discovery ipam frontend

backend:
	cd services/backend && \
	docker build -t $(DOCKER_REPO)/demos/backend:latest -t $(DOCKER_REPO)/demos/backend:$(GIT_SHA) . && \
	docker push --all-tags $(DOCKER_REPO)/demos/backend && \
	gcloud run services update backend \
			--image $(DOCKER_REPO)/demos/backend:$(GIT_SHA) \
			--region $(REGION) \
			--project $(GCP_PROJECT_ID) \

frontend:
	cd services/frontend && \
	gcloud app deploy app.yaml --project $(GCP_PROJECT_ID) --quiet

discovery:
	cd services/discovery && \
	docker build -t $(DOCKER_REPO)/platform/discovery:latest -t $(DOCKER_REPO)/platform/discovery:$(GIT_SHA) . && \
	docker push --all-tags $(DOCKER_REPO)/platform/discovery && \
	gcloud run services update discovery \
			--image $(DOCKER_REPO)/platform/discovery:$(GIT_SHA) \
			--region $(REGION) \
			--project $(GCP_PROJECT_ID) \

ipam:
	cd services/ipam && \
	docker build -t $(DOCKER_REPO)/platform/ipam:latest -t $(DOCKER_REPO)/platform/ipam:$(GIT_SHA) . && \
	docker push --all-tags $(DOCKER_REPO)/platform/ipam && \
	gcloud run services update ipam \
		--image $(DOCKER_REPO)/platform/ipam:$(GIT_SHA) \
		--region $(REGION) \
		--project $(GCP_PROJECT_ID) \

infra:
	terraform -chdir=terraform init
	terraform -chdir=terraform plan -out=tf.plan
	terraform -chdir=terraform apply tf.plan

