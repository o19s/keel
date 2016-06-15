module Keel
  module Generators
    class ConfigGenerator < ::Rails::Generators::Base
      desc "Generates a the config file for GCloud/Kubernetes."

      source_root File.expand_path('../templates', __FILE__)

      def copy_config
        copy_file "gcloud.yml", "config/gcloud.yml"
      end
    end
  end
end
