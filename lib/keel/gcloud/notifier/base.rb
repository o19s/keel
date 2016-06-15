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
        unless ENV['DEPLOY_USERNAME'].nil? || ENV['DEPLOY_USERNAME'] == ''
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
