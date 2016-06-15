require 'yaml'

module Keel::GCloud
  module Kubernetes
    #
    # A class to represent a Kubernetes Pod.
    # It is a simplified view of what Kubernetes returns with only
    # the necessary information required to perform the operations needed.
    #
    class Pod
      attr_accessor :cli, :app, :name, :namespace, :status, :uid

      def initialize **params
        @app        = params[:app]
        @name       = params[:name]
        @namespace  = params[:namespace]
        @status     = params[:status]
        @uid        = params[:uid]

        @cli        = Cli.new
        @prompter   = Prompter.new
      end

      #
      # Parses the returned YAML into objects of the Pod class.
      #
      # @param yaml [Hash] the parsed result of the API call
      # @return [Array<Pod>] an array of Pod objects
      #
      def self.from_yaml yaml
        yaml['items'].map do |item|
          params = {
            app:        item['metadata']['labels']['app'],
            name:       item['metadata']['name'],
            namespace:  item['metadata']['namespace'],
            status:     item['status']['phase'],
            uid:        item['metadata']['uid'],
          }

          self.new params
        end
      end

      #
      # Fetches all the pods from Kubernetes.
      #
      # @param env [String] the namespace/environment for which to fetch the pods
      # @param app [String] the app for which to fetch the pods
      # @return [Hash] the parsed result of the API call
      #
      def self.fetch_all env, app
        command   = "kubectl get po --namespace=#{env} -l app=#{app} -o yaml"
        rcs_yaml  = YAML.load Cli.new.execute(command)
        return false unless rcs_yaml

        self.from_yaml rcs_yaml
      end

      #
      # Checks if the namespace is running by comparing the status attribute.
      #
      # @return [Boolean]
      #
      def running?
        'Running' == self.status
      end

      #
      # Deletes the pod.
      #
      # @return [Boolean] whether the call succeeded or not
      #
      def delete
        @cli.system "kubectl delete po #{self.name} --namespace=#{self.namespace}"
      end

      #
      # Fetches the logs for the pod.
      # If the param +tail+ is set to true, it tails the logs.
      #
      # @param tail [Boolean, nil] flag whether to tail the logs or not
      # @return [Boolean] whether the call succeeded or not
      #
      def logs tail=nil
        f = tail ? '-f ' : ''

        if tail
          @prompter.print 'Fetching logs...'
          @prompter.print 'Use Ctrl-C to stop'
        end

        @cli.system "kubectl logs #{f}#{self.name} --namespace=#{self.namespace} -c=#{self.app}"
      end
    end
  end
end
