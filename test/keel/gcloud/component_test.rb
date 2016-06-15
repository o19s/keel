require 'test_helper'

module Keel::GCloud
  class ComponentTest < Minitest::Test
    def test_that_it_calls_the_components_update_api_for_gcloud
      cli = Minitest::Mock.new
      cli.expect :system_call, nil, ['gcloud components update']

      Cli.stub :new, cli do
        Component.update
      end

      assert cli.verify
    end

    def test_that_it_calls_the_components_install_api_for_gcloud
      cli = Minitest::Mock.new
      cli.expect :system_call, nil, ['gcloud components install kubectl']

      Cli.stub :new, cli do
        Component.install_k8s
      end

      assert cli.verify
    end
  end
end
