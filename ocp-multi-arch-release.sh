#!/bin/bash -x

LOCAL_SECRET_JSON="/root/.docker/config.json"
PRODUCT_REPO=openshift-release-dev
RELEASE_NAME=ocp-release
OCP_RELEASE=4.10.0-rc.1
ARCHITECTURE=ppc64le
#LOCAL_REGISTRY=sys-powercloud-docker-local.artifactory.swg-devops.com
#LOCAL_REPOSITORY=hypershift/ocp-release
LOCAL_REGISTRY=icr.io
LOCAL_REPOSITORY=openshift-release-dev/ocp-release
MAX_PER_REGISTRY=${MAX_PER_REGISTRY:-8}

function join_by { local IFS="$1"; shift; echo "$*"; }

set -x
declare -a ARRAY=()

while read line; do
ARRAY+=("${line}=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}-${line}")
done < <(oc adm release info ${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}-x86_64 -o=name)

comps=$(join_by " " "${ARRAY[@]}")

#/root/oc/oc adm release new --max-per-registry=${MAX_PER_REGISTRY} --allow-missing-images --insecure -a ${LOCAL_SECRET_JSON} \
#--from-release=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}-x86_64 \
#--to-image=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}-x86_64-multi ${comps} --skip-verification --reference-mode=source

#exit 0
/root/oc/oc adm release new --max-per-registry=${MAX_PER_REGISTRY} --allow-missing-images --insecure -a ${LOCAL_SECRET_JSON} \
--from-release=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}-ppc64le \
--to-image=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}-ppc64le-multi ${comps} --skip-verification --reference-mode=source

docker manifest create \
${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}-multi \
  --amend ${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}-x86_64-multi \
  --amend ${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}-ppc64le-multi

docker manifest annotate ${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}-multi ${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}-x86_64-multi --arch amd64 --os linux
docker manifest annotate ${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}-multi ${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}-ppc64le-multi --arch ppc64le --os linux
docker manifest push ${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}-multi
