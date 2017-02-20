require 'yaml'

module Keel::GCloud
  module Kubernetes
    #
    # A class to represent the shared characteristics of a Kubernetes pod
    # manager (eg. Deployment or Replication Controller)
    #
    class PodManager
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
          self.new params
        end
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
