require 'yaml'

module Keel::GCloud
  module Kubernetes
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

      def self.from_yaml yaml
        yaml['items'].map do |item|
          params = {
            containers: item['spec']['template']['spec']['containers'],
            name:       item['metadata']['name'],
            namespace:  item['metadata']['namespace'],
            original:   item,
            uid:        item['metadata']['uid'],
          }

          self.new params
        end
      end

      def self.fetch_all env, app
        command   = "kubectl get rc --namespace=#{env} -l app=#{app} -o yaml"
        rcs_yaml  = YAML.load Cli.new.execute(command)
        return false unless rcs_yaml

        self.from_yaml rcs_yaml
      end

      def self.replace file
        Cli.new.system "kubectl replace -f #{file}"
      end

      def to_yaml
        self.original.to_yaml
      end

      def to_file filename
        File.open(filename, 'w') do |io|
          io.write self.to_yaml
        end
      end

      def increment_replica_count
        self.original['spec']['replicas'] += 1
      end

      def decrement_replica_count
        self.original['spec']['replicas'] -= 1
      end

      def update
        tmp_file = Rails.root.join('tmp', 'deployment-rc.yaml')
        self.to_file tmp_file
        self.class.replace tmp_file
      end
    end
  end
end
