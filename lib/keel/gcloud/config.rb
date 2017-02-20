require 'yaml'

module Keel::GCloud
  #
  # Config file parser.
  # Takes the YAML file and creates an object with attributes matching
  # the supplied configurations.
  #
  # Also serves as a wrapper for the GCloud configurations API.
  #
  class Config
    attr_accessor :cli,
                  :config,
                  :app_name,
                  :compute_region,
                  :compute_zone,
                  :container_app_image_path,
                  :container_cloud_sql_image_path,
                  :container_cluster,
                  :cloud_sql_instance,
                  :env_variables,
                  :project_id

    GCLOUD_OPTIONS_LIST = [:compute_zone, :container_cluster, :project_id]

    def initialize
      @cli    = Cli.new

      path    = ''
      if defined? Rails
        path = Rails.root.join('config', 'gcloud.yml')
      else
        path = File.join(Dir.pwd, 'config.yaml')
      end
      @config = YAML.load_file(path)

      @app_name                       = @config[:app][:name]
      @compute_region                 = @config[:compute][:region]
      @compute_zone                   = @config[:compute][:zone]
      @container_app_image_path       = @config[:container][:app_image_path]
      @container_cloud_sql_image_path = @config[:container][:cloud_sql_image_path]
      @container_cluster              = @config[:container][:cluster]
      @cloud_sql_instance             = @config[:cloud_sql_instance]
      @env_variables                  = @config[:env_variables]
      @project_id                     = @config[:project_id]
    end

    #
    # Lists the GCloud configurations.
    #
    # @return [Array] of configurations
    #
    def self.list
      Cli.new.execute 'gcloud config list'
    end

    #
    # Checks if the gcloud excutable is installed.
    #
    # @return [Boolean]
    #
    def executable_installed?
      @cli.system_call 'which gcloud'
      $?.success?
    end

    #
    # (see #executable_installed?)
    #
    def executable_missing?
      !executable_installed?
    end

    #
    # Gets the application specific configurations for GCloud by checking
    # if any ENV variables are set first, otherwise returning the ones
    # from the config file.
    # This allows the developer to override a config param locally without
    # changing the YAML file.
    #
    # @return [Hash] of config name/value
    #
    def app_config
      values = {}

      GCLOUD_OPTIONS_LIST.each do |option|
        values[option] = ENV[option.to_s.upcase] || self.send(option)
      end

      return values
    end

    #
    # Checks if the user's system is configured properly or if it's missing
    # any configurations.
    #
    # @return [Boolean]
    #
    def system_configured?
      system_configs  = self.class.list
      desired_configs = self.app_config

      desired_configs.values.all? { |config| system_configs.include? config }
    end

    #
    # Sets the appropriate GCloud configurations properties for the system
    # if they are not already set.
    #
    def set_properties
      @cli.system_call "gcloud config set compute/zone #{self.compute_zone}"
      @cli.system_call "gcloud config set container/cluster #{self.container_cluster}"
      @cli.system_call "gcloud config set project #{self.project_id}"
    end
  end
end
