module Keel::GCloud
  class Component
    def self.update
       Cli.new.call 'gcloud components update'
    end

    def self.install_k8s
      Cli.new.call 'gcloud components install kubectl'
    end
  end
end
