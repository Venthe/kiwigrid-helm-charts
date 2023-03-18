require "helper"
require "fluent/plugin/filter_regexp_splitter.rb"
require "test/plugin/test_utilities.rb"

class RegexpSplitterFilterTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup
  end

  test 'Regexp exists' do
    d = create_driver(basic_config)
    time = event_time
    d.run do
      d.feed('filter.test', time, {
         "log"=>"[2023-02-20 17:00:32,939] [main] INFO  com.google.gerrit.server.cache.PersistentCacheBaseFactory : Enabling disk cache /var/gerrit/cache",
         "kubernetes" => {
            "annotations"=> {
              "fluentdPattern"=>'^\[(?<time>.*?)\]\s+\[(?<thread>.*?)\]\s+(?<logLevel>\w+?)\s+(?<package>.*)\s+:\s+(?<message>.*)$'
            }
         }
        })
    end
    assert_equal({
      "log"=>"[2023-02-20 17:00:32,939] [main] INFO  com.google.gerrit.server.cache.PersistentCacheBaseFactory : Enabling disk cache /var/gerrit/cache",
      "time"=>"2023-02-20 17:00:32,939",
      "thread"=>"main",
      "logLevel"=>"INFO",
      "package"=>"com.google.gerrit.server.cache.PersistentCacheBaseFactory",
      "message"=>"Enabling disk cache /var/gerrit/cache",
      "kubernetes" => {
        "annotations"=> {
          "fluentdPattern"=>'^\[(?<time>.*?)\]\s+\[(?<thread>.*?)\]\s+(?<logLevel>\w+?)\s+(?<package>.*)\s+:\s+(?<message>.*)$'
        }
      }
      }, d.filtered_records[0])
  end

  test 'Regexp does not exist' do
    d = create_driver(basic_config)
    time = event_time
    d.run do
      d.feed('filter.test', time, {
         "log"=>"[2023-02-20 17:00:32,939] [main] INFO  com.google.gerrit.server.cache.PersistentCacheBaseFactory : Enabling disk cache /var/gerrit/cache"
        })
    end

    assert_equal({
      "log"=>"[2023-02-20 17:00:32,939] [main] INFO  com.google.gerrit.server.cache.PersistentCacheBaseFactory : Enabling disk cache /var/gerrit/cache",
      "message"=>"[2023-02-20 17:00:32,939] [main] INFO  com.google.gerrit.server.cache.PersistentCacheBaseFactory : Enabling disk cache /var/gerrit/cache"
      }, d.filtered_records[0])
  end

  test 'Regexp different key' do
    d = create_driver(%[
      regexp_key  kubernetes
    ])
    time = event_time
    d.run do
      d.feed('filter.test', time, {
         "log"=>"[2023-02-20 17:00:32,939] [main] INFO  com.google.gerrit.server.cache.PersistentCacheBaseFactory : Enabling disk cache /var/gerrit/cache",
         "kubernetes"=>'^\[(?<time>.*?)\]\s+\[(?<thread>.*?)\]\s+(?<logLevel>\w+?)\s+(?<package>.*)\s+:\s+(?<message>.*)$'
        })
    end

    assert_equal({
      "log"=>"[2023-02-20 17:00:32,939] [main] INFO  com.google.gerrit.server.cache.PersistentCacheBaseFactory : Enabling disk cache /var/gerrit/cache",
      "time"=>"2023-02-20 17:00:32,939",
      "thread"=>"main",
      "logLevel"=>"INFO",
      "package"=>"com.google.gerrit.server.cache.PersistentCacheBaseFactory",
      "message"=>"Enabling disk cache /var/gerrit/cache",
      "kubernetes"=>'^\[(?<time>.*?)\]\s+\[(?<thread>.*?)\]\s+(?<logLevel>\w+?)\s+(?<package>.*)\s+:\s+(?<message>.*)$'
      }, d.filtered_records[0])
  end

  test 'Regexp different default regexp' do
    d = create_driver(%{
      default_pattern ^(?<message2>.*)$
    })
    time = event_time
    d.run do
      d.feed('filter.test', time, {
         "log"=>"[2023-02-20 17:00:32,939] [main] INFO  com.google.gerrit.server.cache.PersistentCacheBaseFactory : Enabling disk cache /var/gerrit/cache"
        })
    end

    assert_equal({
      "log"=>"[2023-02-20 17:00:32,939] [main] INFO  com.google.gerrit.server.cache.PersistentCacheBaseFactory : Enabling disk cache /var/gerrit/cache",
      "message2"=>"[2023-02-20 17:00:32,939] [main] INFO  com.google.gerrit.server.cache.PersistentCacheBaseFactory : Enabling disk cache /var/gerrit/cache"
      }, d.filtered_records[0])
  end

  test 'No key' do
    d = create_driver(basic_config)
    time = event_time
    d.run do
      d.feed('filter.test', time, {
         "log2"=>"[2023-02-20 17:00:32,939] [main] INFO  com.google.gerrit.server.cache.PersistentCacheBaseFactory : Enabling disk cache /var/gerrit/cache"
        })
    end

    assert_equal({
      "log2"=>"[2023-02-20 17:00:32,939] [main] INFO  com.google.gerrit.server.cache.PersistentCacheBaseFactory : Enabling disk cache /var/gerrit/cache"
      }, d.filtered_records[0])
  end

  test 'Default key' do
    d = create_driver('default_key log2')
    time = event_time
    d.run do
      d.feed('filter.test', time, {
         "log2"=>"[2023-02-20 17:00:32,939] [main] INFO  com.google.gerrit.server.cache.PersistentCacheBaseFactory : Enabling disk cache /var/gerrit/cache"
        })
    end

    assert_equal({
      "log2"=>"[2023-02-20 17:00:32,939] [main] INFO  com.google.gerrit.server.cache.PersistentCacheBaseFactory : Enabling disk cache /var/gerrit/cache",
      "message"=>"[2023-02-20 17:00:32,939] [main] INFO  com.google.gerrit.server.cache.PersistentCacheBaseFactory : Enabling disk cache /var/gerrit/cache"
      }, d.filtered_records[0])
  end

  test '2' do
    d = create_driver(basic_config)
    time = event_time
    d.run do
      d.feed('filter.test', time, {"time"=>"2023-03-18T04:26:15.058159355Z", "stream"=>"stderr", "log"=>"time=\"2023-03-18T04:26:15Z\" level=info msg=\"Comparing app state (cluster: https://kubernetes.default.svc, namespace: infrastructure)\" application=infrastructure/backstage-infrastructure", "docker"=>{"container_id"=>"ec0e388de79b78c97fcb887759060a182695c54f08c34b07c55530ecebe49234"}, "kubernetes"=>{"container_name"=>"application-controller", "namespace_name"=>"infrastructure", "pod_name"=>"argocd-application-controller-0", "container_image"=>"quay.io/argoproj/argocd:v2.6.3", "container_image_id"=>"quay.io/argoproj/argocd@sha256:0fd690bd7b89bd6f947b4000de33abd53ebcd36b57216f1c675a1127707b5eef", "pod_id"=>"d648b955-32a8-465c-a219-631237017c27", "pod_ip"=>"192.168.194.159", "host"=>"kubernetes-node-a", "labels"=>{"controller-revision-hash"=>"argocd-application-controller-58465b9c67", "app_kubernetes_io/component"=>"application-controller", "app_kubernetes_io/instance"=>"argocd", "app_kubernetes_io/managed-by"=>"Helm", "app_kubernetes_io/name"=>"argocd-application-controller", "app_kubernetes_io/part-of"=>"argocd", "helm_sh/chart"=>"argo-cd-5.24.0", "statefulset_kubernetes_io/pod-name"=>"argocd-application-controller-0"}, "master_url"=>"https://10.96.0.1:443/api", "namespace_id"=>"2b182aa4-bd86-4453-9c7e-328eee9ba618", "namespace_labels"=>{"name"=>"infrastructure", "kubernetes_io/metadata_name"=>"infrastructure", "pod-security_kubernetes_io/audit"=>"privileged", "pod-security_kubernetes_io/enforce"=>"privileged", "pod-security_kubernetes_io/warn"=>"privileged"}}})
    end

    assert_equal( {"time"=>"2023-03-18T04:26:15.058159355Z", "stream"=>"stderr", "message"=>"time=\"2023-03-18T04:26:15Z\" level=info msg=\"Comparing app state (cluster: https://kubernetes.default.svc, namespace: infrastructure)\" application=infrastructure/backstage-infrastructure", "log"=>"time=\"2023-03-18T04:26:15Z\" level=info msg=\"Comparing app state (cluster: https://kubernetes.default.svc, namespace: infrastructure)\" application=infrastructure/backstage-infrastructure", "docker"=>{"container_id"=>"ec0e388de79b78c97fcb887759060a182695c54f08c34b07c55530ecebe49234"}, "kubernetes"=>{"container_name"=>"application-controller", "namespace_name"=>"infrastructure", "pod_name"=>"argocd-application-controller-0", "container_image"=>"quay.io/argoproj/argocd:v2.6.3", "container_image_id"=>"quay.io/argoproj/argocd@sha256:0fd690bd7b89bd6f947b4000de33abd53ebcd36b57216f1c675a1127707b5eef", "pod_id"=>"d648b955-32a8-465c-a219-631237017c27", "pod_ip"=>"192.168.194.159", "host"=>"kubernetes-node-a", "labels"=>{"controller-revision-hash"=>"argocd-application-controller-58465b9c67", "app_kubernetes_io/component"=>"application-controller", "app_kubernetes_io/instance"=>"argocd", "app_kubernetes_io/managed-by"=>"Helm", "app_kubernetes_io/name"=>"argocd-application-controller", "app_kubernetes_io/part-of"=>"argocd", "helm_sh/chart"=>"argo-cd-5.24.0", "statefulset_kubernetes_io/pod-name"=>"argocd-application-controller-0"}, "master_url"=>"https://10.96.0.1:443/api", "namespace_id"=>"2b182aa4-bd86-4453-9c7e-328eee9ba618", "namespace_labels"=>{"name"=>"infrastructure", "kubernetes_io/metadata_name"=>"infrastructure", "pod-security_kubernetes_io/audit"=>"privileged", "pod-security_kubernetes_io/enforce"=>"privileged", "pod-security_kubernetes_io/warn"=>"privileged"}}}, d.filtered_records[0])
  end
end
