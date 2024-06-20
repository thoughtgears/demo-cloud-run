ifneq (,$(wildcard ./.env))
    include .env
    export
endif

GIT_SHA := $(shell git rev-parse --short HEAD)
DOCKER_REPO := "$(GCP_REGION)-docker.pkg.dev/$(GCP_PROJECT_ID)/platform"

SERVICES := discovery ipam

.PHONY: build push infra

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