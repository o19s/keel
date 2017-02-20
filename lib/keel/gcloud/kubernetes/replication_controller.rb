require 'yaml'

module Keel::GCloud
  module Kubernetes
    #
    # A class to represent a Kubernetes ReplicationController.
    # It is a simplified view of what Kubernetes returns with only
    # the necessary information required to perform the operations needed.
    #
    class ReplicationController < PodManager
      #
      # Fetches the correct replication controller from Kubernetes.
      #
      # @param env [String] the namespace/environment for which to fetch the controllers
      # @param app [String] the app for which to fetch the controllers
      # @return [Hash] the parsed result of the API call
      #
      def self.fetch_all env, app
        command = "kubectl get rc --namespace=#{env} -l app=#{app} -o yaml"
        rcs_yaml = YAML.load Cli.new.execute(command)
        return [] unless rcs_yaml["items"].count > 0
        self.from_yaml rcs_yaml 
      end

      #
      # Find a replication controller by name
      #
      # @param env [String] the namespace/environment for which to fetch the controllers
      # @param name [String] the name of the replication controller
      # @return a ReplicationController
      #
      def self.find env, name
        command = "kubectl get rc --namespace=#{env} #{name} -o yaml"
        rcs_yaml = YAML.load Cli.new.execute(command)
        return false unless rcs_yaml["items"].count > 0
        self.from_yaml rcs_yaml 
      end


      # #
      # # Increments the number of replicas.
      # #
      # def increment_replica_count
      #   self.original['spec']['replicas'] += 1
      # end

      # #
      # # Decrements the number of replicas.
      # #
      # def decrement_replica_count
      #   self.original['spec']['replicas'] -= 1
      # end


    end
  end
end
