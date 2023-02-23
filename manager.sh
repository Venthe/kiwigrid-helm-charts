#!/usr/bin/env bash

set -o errexit
set -o pipefail

function deploy() {
    mkdir -p dist && helm package -d dist ./chart

    helm plugin install https://github.com/chartmuseum/helm-push || true
    helm repo add hosted https://nexus.home.arpa/repository/helm-hosted/ || true
    helm cm-push \
    --username=admin \
    --password=secret \
    ./dist/fluentd-opensearch-13.9.1.tgz \
    --context-path=/repository/helm-hosted/ \
    hosted
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

${@}