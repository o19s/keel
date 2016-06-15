module Keel::GCloud
  #
  # This is a wrapper to call authentication related APIs with GCloud.
  #
  class Auth
    attr_accessor :cli, :config

    def initialize config:
      @config = config
      @cli    = Cli.new
    end

    #
    # Calls the `login` API for GCLoud.
    #
    # @return [Boolean] whether the call succeeded or not
    #
    def self.authenticate
      Cli.new.system_call 'gcloud auth login'
    end

    #
    # Calls the `get-credentials` API for GCLoud for a specific
    # container/cluster.
    #
    # @return [Boolean] whether the call succeeded or not
    #
    def authenticate_k8s
      @cli.system_call "gcloud container clusters get-credentials #{self.config.container_cluster}"
    end
  end
end
