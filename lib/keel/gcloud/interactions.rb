module Keel::GCloud
  #
  # A helper for prompts that integrate other services
  #
  class Interactions
    @@namespace = nil
    @@label       = nil

    #
    # Prompts for the deployment namespace if there are multiple available and one has
    # not been already chosen
    #
    # @param namespace [String] the default option to present for the namespace
    #
    def self.pick_namespace(namespace)
      unless @@namespace
        prompter  = Keel::GCloud::Prompter.new
        # Fetch namespaces from k8s
        namespaces 	= Keel::GCloud::Kubernetes::Namespace.fetch_all
        unless namespaces
          message = 'Unable to connect to Kubernetes, please try again later...'
          prompter.print message, :error
          abort
        end
        @@namespace  = prompter.prompt_for_namespace namespaces, namespace
      end
      @@namespace
    end

    #
    # Prompts for a Docker image label if one has not already been selected
    #
    # @params label [String] the default value to present to the user
    def self.pick_image_label(label)
      unless @@label
        prompter  = Keel::GCloud::Prompter.new
        @@label = prompter.prompt_for_label label
      end
      @@label
    end
  end
end