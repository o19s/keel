require 'test_helper'

module Keel::GCloud::Kubernetes
  class PodTest < Minitest::Test
    def setup
      @env = 'foo'
      @app = 'bar'
    end

    def test_that_it_calls_the_get_namespaces_api_for_k8s
      cli = Minitest::Mock.new
      cli.expect :execute, '', ["kubectl get po --namespace=#{@env} -l app=#{@app} -o yaml"]

      Keel::GCloud::Cli.stub :new, cli do
        Pod.fetch_all @env, @app
      end

      assert cli.verify
    end

    def test_that_it_returns_false_if_no_namespaces_are_returned
      cli = Minitest::Mock.new
      cli.expect :execute, '', ["kubectl get po --namespace=#{@env} -l app=#{@app} -o yaml"]

      Keel::GCloud::Cli.stub :new, cli do
        assert !Pod.fetch_all(@env, @app)
      end

      assert cli.verify
    end

    def test_that_it_returns_an_array_of_namespaces
      mock_yaml = <<-EOS
apiVersion: v1
items:
- apiVersion: v1
  kind: Pod
  metadata:
    annotations:
      kubernetes.io/created-by: |
        {"kind":"SerializedReference","apiVersion":"v1","reference":{"kind":"ReplicationController","namespace":"#{@env}","name":"#{@env}-#{@app}-controller","uid":"123","apiVersion":"v1","resourceVersion":"2844960"}}
    creationTimestamp: 2016-06-14T20:05:22Z
    generateName: #{@env}-#{@app}-controller
    labels:
      app: #{@app}
    name: #{@env}-#{@app}-controller-123
    namespace: #{@env}
    resourceVersion: "2844987"
    selfLink: /api/v1/namespaces/#{@env}/pods/#{@env}-#{@app}-controller-123
    uid: 123
  status:
    phase: Running
EOS
      cli = Minitest::Mock.new
      cli.expect :execute, mock_yaml, ["kubectl get po --namespace=#{@env} -l app=#{@app} -o yaml"]

      Keel::GCloud::Cli.stub :new, cli do
        result = Pod.fetch_all(@env, @app)
        assert_kind_of Array, result

        first = result[0]
        assert_instance_of Pod, first
      end
    end

    def test_that_it_deletes_a_pod
      cli = Minitest::Mock.new
      cli.expect :system, nil, ["kubectl delete po a_pod --namespace=#{@env}"]

      Keel::GCloud::Cli.stub :new, cli do
        pod = Pod.new(
          app:       @app,
          name:      'a_pod',
          namespace: @env,
          status:    'Running',
          uid:       '123'
        )

        pod.delete
      end

      assert cli.verify
    end

    def test_that_it_fetches_the_logs_for_a_pod
      cli = Minitest::Mock.new
      cli.expect :system, nil, ["kubectl logs a_pod --namespace=#{@env} -c=#{@app}"]

      Keel::GCloud::Cli.stub :new, cli do
        pod = Pod.new(
          app:       @app,
          name:      'a_pod',
          namespace: @env,
          status:    'Running',
          uid:       '123'
        )

        pod.logs
      end

      assert cli.verify
    end

    def test_that_it_tails_the_logs_for_a_pod
      cli = Minitest::Mock.new
      cli.expect :system, nil, ["kubectl logs -f a_pod --namespace=#{@env} -c=#{@app}"]

      prompter = Minitest::Mock.new
      prompter.expect :print, nil, [String]
      prompter.expect :print, nil, [String]

      Keel::GCloud::Cli.stub :new, cli do
        Keel::GCloud::Prompter.stub :new, prompter do
          pod = Pod.new(
            app:       @app,
            name:      'a_pod',
            namespace: @env,
            status:    'Running',
            uid:       '123'
          )

          pod.logs true
        end
      end

      assert cli.verify
    end
  end
end
