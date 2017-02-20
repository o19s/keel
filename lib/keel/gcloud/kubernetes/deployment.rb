module Keel::GCloud
    module Kubernetes
        #
        # A class to represent a Kubernetes Deployment
        class Deployment < PodManager

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
                return [] unless rcs_yaml["items"].count > 0
                self.from_yaml rcs_yaml 
            end

            # 
            # Create a Deployment and expose it on kubernetes
            #
            def self.create app_name, image_path, port, sha, namespace
                cli            = Cli.new
                deploy_command = "kubectl run #{app_name} --image=#{image_path}:#{sha} --namespace=#{namespace}"
                expose_command = "kubectl expose deployment #{app_name} --port=80 --target-port=#{port} --type=LoadBalancer --namespace=#{namespace}"
                cli.execute(deploy_command)
                cli.execute(expose_command)
            end
      
        end
    end
end