require 'yaml'

module Keel::GCloud
  module Kubernetes
    class Namespace
      attr_accessor :cli, :name, :status, :uid

      def initialize **params
        @name   = params[:name]
        @status = params[:status]
        @uid    = params[:uid]

        @cli    = Cli.new
      end

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

      def self.fetch_all
        command         = 'kubectl get namespaces -o yaml'
        namespaces_yaml = YAML.load Cli.new.execute(command)
        return false unless namespaces_yaml

        self.from_yaml namespaces_yaml
      end

      def active?
        'Active' == self.status
      end
    end
  end
end
