module Keel::GCloud
  class Component
    def self.update
      Cli.new.system 'gcloud components update'
    end

    def self.install_k8s
      Cli.new.system 'gcloud components install kubectl'
    end
  end
end
