require 'test_helper'

module Keel::GCloud::Kubernetes
  class NamespaceTest < Minitest::Test
    def test_that_it_calls_the_get_namespaces_api_for_k8s
      cli = Minitest::Mock.new
      cli.expect :execute, '', ['kubectl get namespaces -o yaml']

      Keel::GCloud::Cli.stub :new, cli do
        Namespace.fetch_all
      end

      assert cli.verify
    end

    def test_that_it_returns_false_if_no_namespaces_are_returned
      cli = Minitest::Mock.new
      cli.expect :execute, '', ['kubectl get namespaces -o yaml']

      Keel::GCloud::Cli.stub :new, cli do
        assert !Namespace.fetch_all
      end

      assert cli.verify
    end

    def test_that_it_returns_an_array_of_namespaces
      mock_yaml = <<-EOS
apiVersion: v1
items:
- apiVersion: v1
  kind: Namespace
  metadata:
    creationTimestamp: 2015-12-29T20:00:33Z
    labels:
      name: all
    name: all
    resourceVersion: "209549"
    selfLink: /api/v1/namespaces/all
    uid: d213972c-ae66-11e5-b324-42010af00034
  spec:
    finalizers:
    - kubernetes
  status:
    phase: Active
EOS
      cli = Minitest::Mock.new
      cli.expect :execute, mock_yaml, ['kubectl get namespaces -o yaml']

      Keel::GCloud::Cli.stub :new, cli do
        result = Namespace.fetch_all
        assert_kind_of Array, result

        first = result[0]
        assert_instance_of Namespace, first
      end
    end
  end
end
