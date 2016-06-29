require 'yaml'

module Keel::GCloud
  module Kubernetes
    #
    # A class to represent a Kubernetes ReplicationController.
    # It is a simplified view of what Kubernetes returns with only
    # the necessary information required to perform the operations needed.
    #
    class ReplicationController
      attr_accessor :containers, :name, :namespace, :original, :uid

      def initialize **params
        @containers = params[:containers]
        @name       = params[:name]
        @namespace  = params[:namespace]
        @uid        = params[:uid]

        @original   = params[:original]
        @original['metadata'].delete 'creationTimestamp'
      end

      #
      # Parses the returned YAML into objects of the ReplicationController class.
      #
      # @param yaml [Hash] the parsed result of the API call
      # @return [Array<ReplicationController>] an array of ReplicationController objects
      #
      def self.from_yaml yaml
        yaml['items'].map do |item|
          params = {
            containers: item['spec']['template']['spec']['containers'],
            name:       item['metadata']['name'],
            namespace:  item['metadata']['namespace'],
            original:   item,
            uid:        item['metadata']['uid'],
          }
          pp params
          self.new params
        end
      end

      #
      # Fetches the correct deployment or replication controller from Kubernetes.
      #
      # @param env [String] the namespace/environment for which to fetch the controllers
      # @param app [String] the app for which to fetch the controllers
      # @return [Hash] the parsed result of the API call
      #
      def self.fetch_all env, app
        commands   = [
          "kubectl get rc --namespace=#{env} -l app=#{app} -o yaml",
          "kubectl get deployment --namespace=#{env} -l run=#{app} -o yaml"
        ]
        rcs_yaml = nil
        for command in commands.each
          rcs_yaml = YAML.load Cli.new.execute(command)
          break if rcs_yaml["items"].count > 0  # kubernetes object found!
        end

        return false unless rcs_yaml["items"].count > 0
        self.from_yaml rcs_yaml
      end

      #
      # Replaces the controller's specifications with a new one.
      #
      # @param file [File] the new specifications file
      # @return [Boolean] whether the call succeeded or not
      #
      def self.replace file
        Cli.new.system_call "kubectl replace -f #{file}"
      end

      # 
      # Create a Deployment and expose it on kubernetes
      #
      def self.create namespace, app_name, project_id, port, sha
        cli            = Cli.new
        deploy_command = "kubectl run #{app_name} --image=gcr.io/#{project_id}/#{app_name}:#{sha} --namespace=#{namespace}"
        expose_command = "kubectl expose deployment #{app_name} --port=80 --target-port=#{port} --type=LoadBalancer --namespace=#{namespace}"
        cli.execute(deploy_command)
        cli.execute(expose_command)
      end
      
      #
      # Get the YAML representation of the controller.
      #
      # @return [String] the YAML format
      #
      def to_yaml
        self.original.to_yaml
      end

      #
      # Writes the current specifications to a file.
      #
      # @param filename [String] the name of the file to write to
      # @return [Boolean] result of the operation
      #
      def to_file filename
        File.open(filename, 'w') do |io|
          io.write self.to_yaml
        end
      end

      #
      # Increments the number of replicas.
      #
      def increment_replica_count
        self.original['spec']['replicas'] += 1
      end

      #
      # Decrements the number of replicas.
      #
      def decrement_replica_count
        self.original['spec']['replicas'] -= 1
      end

      #
      # Updates the specifications of a controller on Kubernetes
      # with the latest specs.
      #
      # (see #to_file)
      # (see #replace)
      #
      def update
        tmp_file = Rails.root.join('tmp', 'deployment-rc.yml')
        self.to_file tmp_file
        self.class.replace tmp_file
      end
    end
  end
end
