namespace :keel do
  config    = Keel::GCloud::Config.new
  prompter  = Keel::GCloud::Prompter.new

  desc "build a docker image suitable for pushing"
  task :pack, [:deploy_sha] do |_, args|
    prompter.print 'Building Docker image', :info
    image_label  = Keel::GCloud::Interactions.pick_image_label args[:deploy_sha]
    Keel::Docker::Image.create image_label, config.project_id, config.app_name
    prompter.print 'finished build', :info 
  end

  desc "ship the image to gcloud"
  task :push, [:deploy_sha] do |_, args|
    prompter.print 'Pushing image to Docker repository, this may take some time', :info
    image_label  = Keel::GCloud::Interactions.pick_image_label args[:deploy_sha]
    Keel::Docker::Image.push image_label, config.project_id, config.app_name
    prompter.print 'finished push', :info
  end

  desc "provision a deployment and service on kubernetes"
  task :provision, [:deploy_sha] do |_, args|
    image_label = Keel::GCloud::Interactions.pick_image_label args[:deploy_sha]    
    deploy_env  = Keel::GCloud::Interactions.pick_namespace args[:environment]

    # Retrieve a replication controller configuration from the cluster
    rcs = Keel::GCloud::Kubernetes::ReplicationController.fetch_all deploy_env, config.app_name
    if rcs
      message = "Found an existing deployment or replication controller for #{config.app_name}"
      prompter.print message, :success
    else
      message = Keel::GCloud::Kubernetes::ReplicationController.create config.app_name, config.container_app_image_path, "3000", image_label, deploy_env
      prompter.print message, :success
    end
  end

  task :shipit, [:deploy_sha] => [:set_gcloud_properties,
                                  :pack,
                                  :push,
                                  :provision,
                                  :deploy] do |_, args|
    prompter.print "packed, pushed, provisioned and deployed #{config.app_name}!", :success
  end

  desc 'Deploy the specified SHA to a given environment'
  task :deploy, [:environment, :deploy_sha] do |_, args|
    app         = config.app_name
    deploy_sha  = Keel::GCloud::Interactions.pick_image_label args[:deploy_sha]
    deploy_env  = Keel::GCloud::Interactions.pick_namespace args[:environment]
    #rc_type     = :replication_controller

    # Retrieve a replication controller configuration from the cluster
    rcs = Keel::GCloud::Kubernetes::ReplicationController.fetch_all(deploy_env, app) + Keel::GCloud::Kubernetes::Deployment.fetch_all(deploy_env, app)

    unless rcs
      message = 'Unable to connect to Kubernetes, please try again later...'
      prompter.print message, :error
      abort
    end

    unless rcs.first
      message = "Could not find a replication controller for the \"#{deploy_env}\" environment"
      prompter.print message, :error
      abort
    end

  
    rcs.each do |rc|
      puts "Inspecting configuration for deployment #{rc.name}"
      # Prep deployment:
      # 1. Update image
      controller_has_app_pod = false
      rc.containers.each do |container|        
        if container['image'].start_with? config.container_app_image_path
          puts "  Updating image #{container['image']}"
          container['image'] = "#{config.container_app_image_path}:#{deploy_sha}"
          controller_has_app_pod = true
        else
          puts "  Skipping updating image #{container['image']}"
        end
      end
      next unless controller_has_app_pod
      if rc.is_a? Keel::GCloud::Kubernetes::Deployment
        rc.update
      else
        # Additionally for replication controllers
        # 2. Update replica count
        # 3. Write out to a tmp file
        # 4. Replace the running controller
        #     - this will create 1 new pod with the updated code

        # We can get away with first since it is a single container pod

        rc.increment_replica_count
        rc.update

        # Get a list of pods for the RC, this must be done pre-change
        pods = Keel::GCloud::Kubernetes::Pod.fetch_all deploy_env, rc.original['spec']['selector']
        unless pods
          message = 'Unable to connect to Kubernetes, please try again later...'
          prompter.print message, :error
          abort
        end

        # Iterate over all pods, checking to see if they are running
        all_pods_running = false
        while !all_pods_running do
          prompter.print 'Waiting for new pods to start', :info
          sleep 5
          new_pods = Keel::GCloud::Kubernetes::Pod.fetch_all deploy_env, rc.original['spec']['selector']

          all_pods_running = true
          new_pods.each do |pod|
            if !pod.running?
              prompter.print "Pod \"#{pod.name}\" is not running", :info
              all_pods_running = false
            end
          end
        end

        # Nuke old pods
        pods.each do |pod|
          pod.delete
          sleep 3
        end

        # Bring the replica count down and resubmit to the cluster,
        # this kills the 1 extra pod
        rcs = Keel::GCloud::Kubernetes::ReplicationController.fetch_all deploy_env, app
        rc = rcs.first
        rc.decrement_replica_count
        rc.update
      end
    end
    prompter.print 'Notifying NewRelic of deployment', :info
    notifier = Keel::Notifier::NewRelic.new env: deploy_env, sha: deploy_sha
    notifier.notify

    prompter.print 'Deployment complete', :success
  end

  desc 'Configures the local machine for communication with gcloud and k8s'
  task :setup => [:check_gcloud_executables, 
                  :check_configuration,
                  :update_tools,
                  :gcloud_auth,
                  :set_gcloud_properties,
                  :install_k8s,
                  :authenticate_k8s] 

  task :check_gcloud_executables do

    if config.executable_missing?
      message = 'Install Google Cloud command line tools'
      message += "\n"
      message += 'See: https://cloud.google.com/sdk/'

      abort message.red
    end
  end

  task :check_configuration do

    if config.system_configured?
      abort 'App appears to already be configured on your system.'.green
    end
  end

  task :install_k8s do
    prompter.print 'Install Kubernetes', :info
    Keel::GCloud::Component.install_k8s
  end

  task :authenticate_k8s do
    prompter.print 'Pulling Kubernetes auth configuration', :info
    auth = Keel::GCloud::Auth.new config: config
    auth.authenticate_k8s
  end

  task :gcloud_auth do
    prompter.print 'Authenticating with Google Cloud', :info
    Keel::GCloud::Auth.authenticate
  end

  task :update_tools do
    prompter.print 'Updating tools', :info
    Keel::GCloud::Component.update
  end

  task :set_gcloud_properties do 
    prompter.print 'Setting gcloud properties', :info
    config.set_properties
  end

  desc 'Pulls logs for a given environment'
  task :logs, [:environment] do |_, args|
    app           = config.app_name
    # Prompt the user for the env and to log and whether to tail the logs
    deploy_env    = Keel::GCloud::Interactions.pick_namespace args[:environment]
    tail          = prompter.prompt_for_tailing_logs

    prompter.print "Getting pod information for #{deploy_env}", :info
    pods = Keel::GCloud::Kubernetes::Pod.fetch_all deploy_env, app

    unless pods.length > 0
      message = "Could not find pods in the \"#{deploy_env}\" environment."
      prompter.print message, :error
      abort
    end

    # It seems that the first pod is the one we really want to look at for logs
    pod = pods.first
    pod.logs tail
  end
end
