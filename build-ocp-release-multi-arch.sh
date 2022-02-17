#!/bin/bash

set -x

LOCAL_SECRET_JSON="/root/.docker/config.json"
PRODUCT_REPO=openshift-release-dev
RELEASE_NAME=ocp-release
OCP_RELEASE=4.10.0-rc.1
ARCHITECTURE=x86_64
#LOCAL_REGISTRY=sys-powercloud-docker-local.artifactory.swg-devops.com
#LOCAL_REPOSITORY=hypershift/ocp-release
LOCAL_REGISTRY=icr.io
LOCAL_REPOSITORY=openshift-release-dev/ocp-release

#oc adm release mirror -a ${LOCAL_SECRET_JSON}  \
#     --from=quay.io/${PRODUCT_REPO}/${RELEASE_NAME}:${OCP_RELEASE}-${ARCHITECTURE} \
#     --to=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY} \
#     --to-release-image=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}-${ARCHITECTURE}

oc adm release info quay.io/${PRODUCT_REPO}/${RELEASE_NAME}:${OCP_RELEASE}-x86_64 -o=name | while read line; do  
  echo "line: $line"
  docker manifest create \
	${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}-${line} \
	--amend ${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}-x86_64-${line} \
	--amend ${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}-ppc64le-${line}
  docker manifest annotate ${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}-${line} ${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}-x86_64-${line} --arch amd64 --os linux
  docker manifest annotate ${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}-${line} ${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}-ppc64le-${line} --arch ppc64le --os linux
  docker manifest push ${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}-${line}
done
