#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o xtrace

. .env 2>/dev/null 1>/dev/null || true

DIST_DIRECTORY=dist
CONTEXT_PATH="${CONTEXT_PATH:-repository/helm-hosted/}"
REPOSTORY="${REPOSITORY:-https://nexus.home.arpa/${CONTEXT_PATH}}"
REPOSITORY_USERNAME="${REPOSITORY_USERNAME:-admin}"
REPOSITORY_SECRET="${REPOSITORY_SECRET:-secret}"
TARGET_REPOSITORY_NAME="${TARGET_REPOSITORY_NAME:-hosted}"

function deploy() {
    local chart_name="${1}"
    local chart_archive=`cat charts/${chart_name}/Chart.yaml | yq -e '(.name + "-" + .version + ".tgz")'`

    mkdir -p "${DIST_DIRECTORY}" && helm package -d "${DIST_DIRECTORY}" "./charts/${chart_name}"

    helm plugin install https://github.com/chartmuseum/helm-push || true
    helm repo add "${TARGET_REPOSITORY_NAME}" "${REPOSTORY}" || true
    helm cm-push \
      --username="${REPOSITORY_USERNAME}" \
      --password="${REPOSITORY_SECRET}" \
      "./${DIST_DIRECTORY}/${chart_archive}" \
      --context-path="/${CONTEXT_PATH}" \
      "${TARGET_REPOSITORY_NAME}"
}

function release_local() {
    helm uninstall --namespace infrastructure fluentd-infrastructure || true
    helm upgrade \
      --install \
      --namespace infrastructure \
      --create-namespace \
      --values=./test/values.yml \
      fluentd-infrastructure \
      ./charts/fluentd-opensearch
}

function logs() {
    kubectl logs --namespace infrastructure ds/fluentd-infrastructure-fluentd-opensearch --follow
}

# bash ./manager.sh deploy fluentd-opensearch
${@}