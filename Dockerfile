FROM docker.io/fluent/fluentd-kubernetes-daemonset:v1.15.3-debian-opensearch-1.1

COPY filter_regexp_splitter.rb /fluentd/plugins/
