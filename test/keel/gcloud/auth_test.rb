require 'test_helper'

module Keel::GCloud
  class AuthTest < Minitest::Test
    def test_that_it_calls_the_login_api_for_gcloud
      cli = Minitest::Mock.new
      cli.expect :system_call, nil, ['gcloud auth login']

      Cli.stub :new, cli do
        Auth.authenticate
      end

      assert cli.verify
    end

    def test_that_it_calls_the_container_api_for_gcloud
      cli = Minitest::Mock.new
      cli.expect :system_call, nil, ['gcloud container clusters get-credentials foo']

      config = Minitest::Mock.new
      config.expect :container_cluster, 'foo'

      Cli.stub :new, cli do
        auth = Auth.new config: config
        auth.authenticate_k8s
      end

      assert cli.verify
    end
  end
end
