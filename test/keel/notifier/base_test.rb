require 'test_helper'

module Keel::Notifier
  class BaseTest < Minitest::Test
    def test_that_it_sets_the_user_to_the_result_of_the_whoami_if_no_env_value_exists
      cli = Minitest::Mock.new
      cli.expect :execute, 'me', ['whoami']

      Keel::GCloud::Cli.stub :new, cli do
        notifier = Base.new env: 'env', sha: 'sha'
        assert_equal notifier.user, 'me'
      end

      assert cli.verify
    end

    def test_that_it_sets_the_user_to_the_env_value_if_it_exists
      cli = Minitest::Mock.new
      ENV['DEPLOY_USERNAME'] = 'another_me'

      Keel::GCloud::Cli.stub :new, cli do
        notifier = Base.new env: 'env', sha: 'sha'
        assert_equal notifier.user, 'another_me'
      end

      ENV['DEPLOY_USERNAME'] = nil
    end

    def test_that_it_raises_an_error_when_calling_notify
      cli = Minitest::Mock.new
      cli.expect :execute, 'me', ['whoami']

      Keel::GCloud::Cli.stub :new, cli do
        notifier = Base.new env: 'env', sha: 'sha'
        assert_raises(NotImplemented) { notifier.notify }
      end
    end
  end
end
