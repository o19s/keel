module Keel::GCloud
    module Kubernetes
        #
        # A class to represent a Kubernetes Deployment
        class Deployment < ReplicationController

            #
            # Fetches the correct deployment or replication controller from Kubernetes.
            #
            # @param env [String] the namespace/environment for which to fetch the controllers
            # @param app [String] the app for which to fetch the controllers
            # @return [Hash] the parsed result of the API call
            #
            def self.fetch_all env, app
                command = "kubectl get deployment --namespace=#{env} -l app=#{app} -o yaml"
                rcs_yaml = YAML.load Cli.new.execute(command)
                return false unless rcs_yaml["items"].count > 0
                self.from_yaml rcs_yaml 
            end
        end
    end
end