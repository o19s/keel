module Keel
  module Notifier
    #
    # Notifier for NewRelic that send a deployment notification.
    #
    class NewRelic < Base
      #
      # Sends a notification to NewRelic of a new deployment with the
      # appropriate attributes.
      #
      def notify
        env = @env == 'production' ? 'production' : 'staging'
        @cli.system_call "newrelic deployments -e #{env} -r #{@sha} -u #{@user}"
      end
    end
  end
end
