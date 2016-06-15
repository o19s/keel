module Keel::GCloud
  #
  # Class to help manage GCloud components.
  #
  class Component
    #
    # Updates the installed GCloud components.
    #
    # @return [Boolean] whether the call succeeded or not
    #
    def self.update
      Cli.new.system_call 'gcloud components update'
    end

    #
    # Installs the Kubernetes controller component.
    #
    # @return [Boolean] whether the call succeeded or not
    #
    def self.install_k8s
      Cli.new.system_call 'gcloud components install kubectl'
    end
  end
end
