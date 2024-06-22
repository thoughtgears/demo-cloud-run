ifneq (,$(wildcard ./.env))
    include .env
    export
endif

GIT_SHA := $(shell git rev-parse --short HEAD)
DOCKER_REPO := "$(GCP_REGION)-docker.pkg.dev/$(GCP_PROJECT_ID)/platform"

SERVICES := discovery ipam

.PHONY: build push infra deploy

spacelift:
	cd resources/cloud_build/spacelift && \
	docker build -t gcr.io/$(GCP_PROJECT_ID)/spacelift . && \
	docker run --rm -it gcr.io/$(GCP_PROJECT_ID)/spacelift --api-key $(SPACELIFT_API_KEY) --key-id $(SPACELIFT_API_KEY_ID) --stack-id $(SPACELIFT_STACK_ID) --url $(SPACELIFT_API_URL)

build:
	$(foreach service, $(SERVICES), \
		docker build -t $(DOCKER_REPO)/$(service):$(GIT_SHA) ./services/$(service); \
		docker tag $(DOCKER_REPO)/$(service):$(GIT_SHA) $(DOCKER_REPO)/$(service):latest; \
	)

push: build
	$(foreach service, $(SERVICES), \
		docker push $(DOCKER_REPO)/$(service):$(GIT_SHA); \
		docker push $(DOCKER_REPO)/$(service):latest; \
	)

infra:
	terraform -chdir=terraform init
	terraform -chdir=terraform plan -out=tf.plan
	terraform -chdir=terraform apply tf.plan

deploy: infra push
	$(foreach service, $(SERVICES), \
		gcloud run deploy $(service) \
			--image $(DOCKER_REPO)/$(service):$(GIT_SHA) \
			--region $(REGION) \
			--concurrency 80 \
			--max-instances 1 \
			--timeout 300 \
			--memory 256Mi \
			--cpu 1 \
			--service-account run-$(service)@$(GCP_PROJECT_ID).iam.gserviceaccount.com \
			--project $(GCP_PROJECT_ID) \
			--set-env-vars=GCP_PROJECT_ID=$(GCP_PROJECT_ID),GCP_REGION=$(GCP_REGION),GCP_ORGANIZATION_ID=$(GCP_ORGANIZATION_ID) \
			--noallow-unauthenticated; \
	)
