ifneq (,$(wildcard ./.env))
    include .env
    export
endif

GIT_SHA := $(shell git rev-parse --short HEAD)
DOCKER_REPO := "$(GCP_REGION)-docker.pkg.dev/$(GCP_PROJECT_ID)"

SERVICES := discovery ipam

.PHONY: spacelift backend discovery ipam infra

spacelift:
	cd resources/cloud_build/spacelift && \
	docker build -t gcr.io/$(GCP_PROJECT_ID)/spacelift . && \
	docker run --rm -it gcr.io/$(GCP_PROJECT_ID)/spacelift --api-key $(SPACELIFT_API_KEY) --key-id $(SPACELIFT_API_KEY_ID) --stack-id $(SPACELIFT_STACK_ID) --url $(SPACELIFT_API_URL)

backend:
	cd services/backend && \
	docker build -t $(DOCKER_REPO)/demos/backend:latest -t $(DOCKER_REPO)/demos/backend:$(GIT_SHA) . && \
	docker push --all-tags $(DOCKER_REPO)/demos/backend && \
	gcloud run deploy backend \
			--image $(DOCKER_REPO)/demos/backend:$(GIT_SHA) \
			--region $(REGION) \
			--concurrency 80 \
			--max-instances 1 \
			--timeout 300 \
			--memory 256Mi \
			--cpu 1 \
			--service-account run-backend@$(GCP_PROJECT_ID).iam.gserviceaccount.com \
			--project $(GCP_PROJECT_ID) \
			--set-env-vars=GCP_PROJECT_ID=$(GCP_PROJECT_ID),GCP_REGION=$(GCP_REGION),GCP_ORGANIZATION_ID=$(GCP_ORGANIZATION_ID) \
			--no-allow-unauthenticate

discovery:
	cd services/discovery && \
	docker build -t $(DOCKER_REPO)/platform/discovery:latest -t $(DOCKER_REPO)/platform/discovery:$(GIT_SHA) . && \
	docker push --all-tags $(DOCKER_REPO)/platform/discovery && \
	gcloud run deploy discovery \
			--image $(DOCKER_REPO)/platform/discovery:$(GIT_SHA) \
			--region $(REGION) \
			--concurrency 80 \
			--max-instances 1 \
			--timeout 300 \
			--memory 256Mi \
			--cpu 1 \
			--service-account run-discovery(GCP_PROJECT_ID).iam.gserviceaccount.com \
			--project $(GCP_PROJECT_ID) \
			--set-env-vars=GCP_PROJECT_ID=$(GCP_PROJECT_ID),GCP_REGION=$(GCP_REGION),GCP_ORGANIZATION_ID=$(GCP_ORGANIZATION_ID) \
			--no-allow-unauthenticate

ipam:
	cd services/ipam && \
	docker build -t $(DOCKER_REPO)/platform/ipam:latest -t $(DOCKER_REPO)/platform/ipam:$(GIT_SHA) . && \
	docker push --all-tags $(DOCKER_REPO)/platform/ipam && \
	gcloud run deploy ipam \
			--image $(DOCKER_REPO)/platform/ipam:$(GIT_SHA) \
			--region $(REGION) \
			--concurrency 80 \
			--max-instances 1 \
			--timeout 300 \
			--memory 256Mi \
			--cpu 1 \
			--service-account run-ipam(GCP_PROJECT_ID).iam.gserviceaccount.com \
			--project $(GCP_PROJECT_ID) \
			--set-env-vars=GCP_PROJECT_ID=$(GCP_PROJECT_ID),GCP_REGION=$(GCP_REGION),GCP_ORGANIZATION_ID=$(GCP_ORGANIZATION_ID) \
			--no-allow-unauthenticate

infra:
	terraform -chdir=terraform init
	terraform -chdir=terraform plan -out=tf.plan
	terraform -chdir=terraform apply tf.plan

