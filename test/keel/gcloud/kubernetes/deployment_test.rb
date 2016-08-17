require 'test_helper'

module Keel::GCloud::Kubernetes
    class DeploymentTest < Minitest::Test
        def setup
            @env = 'foo'
            @app = 'bar'
            @empty_kubectl_response = <<-EOS
apiVersion: v1
items: []
kind: List
metadata: {}
            EOS
        end

        def test_that_it_returns_false_if_no_namespaces_are_returned
            
            cli = Minitest::Mock.new
            cli.expect :execute, @empty_kubectl_response, ["kubectl get deployment --namespace=#{@env} -l app=#{@app} -o yaml"]

            Keel::GCloud::Cli.stub :new, cli do
                assert !Deployment.fetch_all(@env, @app)
            end

            assert cli.verify
        end
    end
end