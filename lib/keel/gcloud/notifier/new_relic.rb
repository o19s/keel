module Keel::GCloud
  module Notifier
    class NewRelic < Base
      def notify
        env = @env == 'production' ? 'production' : 'staging'
        @cli.system "newrelic deployments -e #{env} -r #{@sha} -u #{@user}"
      end
    end
  end
end
