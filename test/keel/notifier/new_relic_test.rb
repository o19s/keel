require 'test_helper'

module Keel::Notifier
  class NewRelicTest < Minitest::Test
    def test_that_it_calls_the_new_relic_client_to_notify_of_deployment
      cli = Minitest::Mock.new
      cli.expect :execute, 'me', ['whoami']
      cli.expect :system_call, nil, ['newrelic deployments -e staging -r sha -u me']

      Keel::GCloud::Cli.stub :new, cli do
        notifier = NewRelic.new env: 'env', sha: 'sha'
        notifier.notify
      end

      assert cli.verify
    end
  end
end
