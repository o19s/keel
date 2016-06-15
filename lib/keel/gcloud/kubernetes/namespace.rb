require 'yaml'

module Keel::GCloud
  module Kubernetes
    #
    # A class to represent a Kubernetes Namespace.
    # It is a simplified view of what Kubernetes returns with only
    # the necessary information required to perform the operations needed.
    #
    class Namespace
      attr_accessor :cli, :name, :status, :uid

      def initialize **params
        @name   = params[:name]
        @status = params[:status]
        @uid    = params[:uid]

        @cli    = Cli.new
      end

      #
      # Parses the returned YAML into objects of the Namespace class.
      #
      # @param yaml [Hash] the parsed result of the API call
      # @return [Array<Namespace>] an array of Namespace objects
      #
      def self.from_yaml yaml
        yaml['items'].map do |item|
          params = {
            name:   item['metadata']['name'],
            status: item['status']['phase'],
            uid:    item['metadata']['uid'],
          }

          self.new params
        end
      end

      #
      # Fetches all the namespaces from Kubernetes.
      #
      # @return [Hash] the parsed result of the API call
      #
      def self.fetch_all
        command         = 'kubectl get namespaces -o yaml'
        namespaces_yaml = YAML.load Cli.new.execute(command)
        return false unless namespaces_yaml

        self.from_yaml namespaces_yaml
      end

      #
      # Checks if the namespace is active by comparing the status attribute.
      #
      # @return [Boolean]
      #
      def active?
        'Active' == self.status
      end
    end
  end
end
