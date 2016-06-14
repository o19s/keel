require 'yaml'

module Keel::GCloud
  module Kubernetes
    class Pod
      attr_accessor :cli, :app, :name, :namespace, :status, :uid

      def initialize **params
        @app        = params[:app]
        @name       = params[:name]
        @namespace  = params[:namespace]
        @status     = params[:status]
        @uid        = params[:uid]

        @cli        = Cli.new
      end

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

      def self.fetch_all env, app
        command   = "kubectl get po --namespace=#{env} -l app=#{app} -o yaml"
        rcs_yaml  = YAML.load Cli.new.execute(command)
        return false unless rcs_yaml

        self.from_yaml rcs_yaml
      end

      def running?
        'Running' == self.status
      end

      def delete
        @cli.call "kubectl delete po #{self.name} --namespace=#{self.namespace}"
      end

      def logs tail
        f = tail ? '-f' : ''

        if tail
          puts 'Fetching logs...'
          puts 'Use Ctrl-C to stop'
        end

        @cli.call "kubectl logs #{f} #{self.name} --namespace=#{self.namespace} -c=#{self.app}"
      end
    end
  end
end
