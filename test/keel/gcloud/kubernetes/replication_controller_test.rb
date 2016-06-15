require 'test_helper'

module Keel::GCloud::Kubernetes
  class ReplicationControllerTest < Minitest::Test
    def setup
      @env = 'foo'
      @app = 'bar'
    end

    def test_that_it_calls_the_get_namespaces_api_for_k8s
      cli = Minitest::Mock.new
      cli.expect :execute, '', ["kubectl get rc --namespace=#{@env} -l app=#{@app} -o yaml"]

      Keel::GCloud::Cli.stub :new, cli do
        ReplicationController.fetch_all @env, @app
      end

      assert cli.verify
    end

    def test_that_it_returns_false_if_no_namespaces_are_returned
      cli = Minitest::Mock.new
      cli.expect :execute, '', ["kubectl get rc --namespace=#{@env} -l app=#{@app} -o yaml"]

      Keel::GCloud::Cli.stub :new, cli do
        assert !ReplicationController.fetch_all(@env, @app)
      end

      assert cli.verify
    end

    def test_that_it_returns_an_array_of_namespaces
      mock_yaml = <<-EOS
apiVersion: v1
items:
- apiVersion: v1
  kind: ReplicationController
  metadata:
    creationTimestamp: 2015-12-30T15:46:07Z
    generation: 225
    labels:
      app: #{@app}
    name: #{@env}-#{@app}-controller
    namespace: #{@env}
    resourceVersion: "2845016"
    selfLink: /api/v1/namespaces/#{@env}/ReplicationControllers/#{@env}-#{@app}-controller-123
    uid: 123
  spec:
    replicas: 6
    selector:
      app: #{@app}
    template:
      metadata:
        creationTimestamp: null
        labels:
          app: #{@app}
        name: #{@app}
      spec:
        containers:
EOS
      cli = Minitest::Mock.new
      cli.expect :execute, mock_yaml, ["kubectl get rc --namespace=#{@env} -l app=#{@app} -o yaml"]

      Keel::GCloud::Cli.stub :new, cli do
        result = ReplicationController.fetch_all(@env, @app)
        assert_kind_of Array, result

        first = result[0]
        assert_instance_of ReplicationController, first
      end
    end

    def test_that_it_replaces_a_controller
      cli = Minitest::Mock.new
      cli.expect :system_call, nil, ["kubectl replace -f foo"]

      Keel::GCloud::Cli.stub :new, cli do
        ReplicationController.replace 'foo'
      end

      assert cli.verify
    end

    def test_that_it_increments_the_replica_count
      controller = ReplicationController.new(
        containers:   @app,
        name:         'a_controller',
        namespace:    @env,
        original:    {
          'metadata' => {
            'creationTimestamp' => 'foo'
          },
          'spec' => {
            'replicas' => 1
          }
        }
      )
      original = controller.original['spec']['replicas']

      controller.increment_replica_count

      assert_equal original + 1, controller.original['spec']['replicas']
    end

    def test_that_it_decrements_the_replica_count
      controller = ReplicationController.new(
        containers:   @app,
        name:         'a_controller',
        namespace:    @env,
        original:    {
          'metadata' => {
            'creationTimestamp' => 'foo'
          },
          'spec' => {
            'replicas' => 1
          }
        }
      )
      original = controller.original['spec']['replicas']

      controller.decrement_replica_count

      assert_equal original - 1, controller.original['spec']['replicas']
    end
  end
end
