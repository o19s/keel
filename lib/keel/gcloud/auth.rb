module Keel::GCloud
  class Auth
    attr_accessor :cli, :config

    def initialize config:
      @config = config
      @cli    = Cli.new
    end

    def self.authenticate
      Cli.new.system 'gcloud auth login'
    end

    def authenticate_k8s
      @cli.system "gcloud container clusters get-credentials #{self.config.container_cluster}"
    end
  end
end
