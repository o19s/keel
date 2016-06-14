module Keel::GCloud
  class Templater
    def initialize config:, env:, **rest
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

    def generate template_name
      template  = File.read(Rails.root.join('ops', "gc-#{template_name}.yaml.erb"))
      buffer    = ERB.new(template, nil, '-').result(binding)

      # Prefix the puts lines with '#' so the output may be piped to a file
      puts "# Generated #{template_name}"
      puts '# --------------------'
      puts buffer
    end
  end
end
