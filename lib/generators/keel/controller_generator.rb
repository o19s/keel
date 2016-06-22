# TODO, kill these and their templates
module Keel
  module Generators
    class ControllerGenerator < ::Rails::Generators::Base
      desc "Generates a Kubernetes replication controller configuration file."

      source_root File.expand_path('../templates', __FILE__)

      def generate_template
        config    = Keel::GCloud::Config.new
        prompter  = Keel::GCloud::Prompter.new

        # Fetch namespaces from k8s
        namespaces = Keel::GCloud::Kubernetes::Namespace.fetch_all
        unless namespaces
          message = 'Unable to connect to Kubernetes, please try again later...'
          prompter.print message, :error
          return
        end

        # Prompt the user for the env, database url, and secret key to be used
        deploy_env    = prompter.prompt_for_namespace namespaces
        database_url  = prompter.prompt_for_database_url
        secret_key    = prompter.prompt_for_secret_key

        if deploy_env.blank? || database_url.blank? || secret_key.blank?
          message = 'Missing required parameters'
          prompter.print message, :error
          return
        end

        set_params(
          config:       config,
          env:          deploy_env,
          database_url: database_url,
          secret_key:   secret_key
        )

        template "gc-controller.yml.erb", "ops/#{@params[:app]}-controller.yml"
      end

      private

      def set_params config:, env:, **rest
        # Setup variables to fill the template
        @params = {
          app:                            config.app_name,
          cloud_sql_instance:             config.cloud_sql_instance[env.to_sym],
          compute_region:                 config.compute_region,
          container_app_image_path:       config.container_app_image_path,
          container_cloud_sql_image_path: config.container_cloud_sql_image_path,
          container_cluster:              config.container_cluster,
          deploy_env:                     env,
          env_variables:                  config.env_variables[env.to_sym],
          rails_env:                      env == 'production' ? 'production' : 'staging',
        }.merge(rest)
      end
    end
  end
end
