#
# Parameters
#

# Name of the docker executable
DOCKER = imagefiles/docker.sh

# Docker organization to pull the images from
ORG = dockbuild

IMAGES = centos5 centos6 centos7

# These images are built using the "build implicit rule"
ALL_IMAGES = $(IMAGES)

#
# images: This target builds all IMAGES (because it is the first one, it is built by default)
#
images: $(IMAGES)

#
# display
#
display_images:
	for image in $(ALL_IMAGES); do echo $$image; done

$(VERBOSE).SILENT: display_images

#
# build implicit rule
#

$(ALL_IMAGES): %: %/Dockerfile
	mkdir -p $@/imagefiles && cp -r imagefiles $@/
	$(DOCKER) build --cache-from=`cat $@/Dockerfile | grep "^FROM" | head -n1 | cut -d" " -f2`,$(ORG)/$@:latest -t $(ORG)/$@:latest \
		--build-arg IMAGE=$(ORG)/$@:latest \
		--build-arg VCS_REF=`git rev-parse --short HEAD` \
	  --build-arg VCS_URL=`git config --get remote.origin.url` \
		--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
		$@
	$(DOCKER) rmi $$($(DOCKER) images -f "dangling=true" -q) || true
	rm -rf $@/imagefiles

.SECONDEXPANSION:
$(addsuffix .run,$(ALL_IMAGES)):
	$(DOCKER) run -ti --rm $(ORG)/$(basename $@):latest bash

.PHONY: images display_images $(ALL_IMAGES) $(addsuffix .run,$(ALL_IMAGES))
