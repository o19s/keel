class NotImplemented < StandardError; end

module Keel::GCloud
  module Notifier
    class Base
      attr_accessor :cli, :env, :sha, :user

      def initialize env:, sha:
        @env = env
        @sha = sha

        @cli = Cli.new

        set_user
      end

      def set_user
        if ENV['DEPLOY_USERNAME'].present?
          return @user = ENV['DEPLOY_USERNAME']
        end

        whoami  = @cli.execute 'whoami'
        @user   = whoami.chomp
      end

      def notify
        raise NotImplemented
      end
    end
  end
end
