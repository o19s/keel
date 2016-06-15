require 'yaml'

module Keel::GCloud
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
      @config = YAML.load_file(Rails.root.join('config', 'gcloud.yml'))

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

    def self.list
      Cli.new.execute 'gcloud config list'
    end

    def executable_installed?
      @cli.system 'which gcloud'
      $?.success?
    end

    def executable_missing?
      !executable_installed?
    end

    def app_config
      values = {}

      GCLOUD_OPTIONS_LIST.each do |option|
        values[option] = ENV[option.to_s.upcase] || self.send(option)
      end

      return values
    end

    def system_configured?
      system_configs  = self.class.list
      desired_configs = self.app_config

      desired_configs.values.all? { |config| system_configs.include? config }
    end

    def set_properties
      @cli.system "gcloud config set compute/zone #{self.compute_zone}"
      @cli.system "gcloud config set container/cluster #{self.container_cluster}"
      @cli.system "gcloud config set project #{self.project_id}"
    end
  end
end
