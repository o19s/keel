class NotImplemented < StandardError; end

module Keel::GCloud
  module Notifier
    #
    # Base class to be inherited for notifiers that are used to send any
    # notifications when a deployment is complete.
    #
    class Base
      attr_accessor :cli, :env, :sha, :user

      def initialize env:, sha:
        @env = env
        @sha = sha

        @cli = Cli.new

        set_user
      end

      #
      # Determines the user id to be sent with the nofications
      # based on the ENV variable if set, otherwise on the system user.
      #
      def set_user
        unless ENV['DEPLOY_USERNAME'].nil? || ENV['DEPLOY_USERNAME'] == ''
          return @user = ENV['DEPLOY_USERNAME']
        end

        whoami  = @cli.execute 'whoami'
        @user   = whoami.chomp
      end

      def notify # :nodoc:
        raise NotImplemented
      end
    end
  end
end
