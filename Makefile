DOCKER_TAG ?= latest
PLATFORM ?= intel
DOCKER_REPO ?= kinetica-$(PLATFORM)

# DOCKER_REPO: the name of the Docker repository being built.
# DOCKER_TAG: the Docker repository tag being built.

.PHONY: all
all: kinetica-$(PLATFORM)-$(DOCKER_TAG)

.PHONY: kinetica-$(PLATFORM)-$(DOCKER_TAG)
kinetica-$(PLATFORM)-$(DOCKER_TAG): 
	docker build --build-arg platform=$(PLATFORM) --build-arg release=$(DOCKER_TAG) -t $(DOCKER_REPO):$(DOCKER_TAG)  .