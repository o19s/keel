namespace :keel do
  def pick_sha(sha)
    unless @sha
      prompter  = Keel::GCloud::Prompter.new
      @sha = prompter.prompt_for_sha sha
    end
    @sha
  end

  def pick_namespace(namespace)
    unless @namespace
      prompter  = Keel::GCloud::Prompter.new
      # Fetch namespaces from k8s
      namespaces 	= Keel::GCloud::Kubernetes::Namespace.fetch_all
      unless namespaces
        message = 'Unable to connect to Kubernetes, please try again later...'
        prompter.print message, :error
        abort
      end
      @namespace  = prompter.prompt_for_namespace namespaces, namespace
    end
    @namespace
  end

  desc "build a docker image suitable for pushing"
  task :pack, [:deploy_sha] do |_, args|
    config    = Keel::GCloud::Config.new

    #TODO warn about the madness of dirty folders, and the fact that we aren't really checking anything!
    pack_sha  = pick_sha(args[:deploy_sha])
    command   = "docker build -t gcr.io/#{config.project_id}/#{config.app_name}:#{pack_sha} ."
    puts command
    Keel::GCloud::Cli.new.execute(command)
  end

  desc "ship the image to gcloud"
  task :push, [:deploy_sha] do |_, args|
    config    = Keel::GCloud::Config.new

    #TODO figure out if the sha is something we can actually deploy
    pack_sha  = pick_sha(args[:deploy_sha])
    command   = "gcloud docker push gcr.io/#{config.project_id}/#{config.app_name}:#{pack_sha}"
    puts command
    Keel::GCloud::Cli.new.execute(command)
  end

  desc "provision a deployment and service on kubernetes"
  task :provision, [:deploy_sha] do |_, args|
    config    	= Keel::GCloud::Config.new
    prompter  	= Keel::GCloud::Prompter.new
    pack_sha  	= pick_sha(args[:deploy_sha])
    
    deploy_env  = pick_namespace args[:environment]

    # Retrieve a replication controller configuration from the cluster
    rcs = Keel::GCloud::Kubernetes::ReplicationController.fetch_all deploy_env, config.app_name
    if rcs
      message = "Found an existing deployment or replication controller for #{config.app_name}"
      prompter.print message, :error
    else
      message = Keel::GCloud::Kubernetes::ReplicationController.create namespace, config.app_name, config.project_id, "3000", pack_sha
      prompter.print message, :info
    end
  end

    task :shipit, [:deploy_sha] => [:set_gcloud_properties,
                                  :pack,
                                  :push,
                                  :provision,
                                  :deploy] do |_, args|
    puts "packed, pushed, provisioned and deployed #{pick_sha(args[:deploy_sha])}!"
  end

  desc 'Deploy the specified SHA to a given environment'
  task :deploy, [:environment, :deploy_sha] do |_, args|
    prompter  	= Keel::GCloud::Prompter.new
    config    	= Keel::GCloud::Config.new
    app       	= config.app_name
    deploy_env  = pick_namespace args[:environment]
    deploy_sha  = pick_sha(args[:deploy_sha])

    # Retrieve a replication controller configuration from the cluster
    rcs = Keel::GCloud::Kubernetes::ReplicationController.fetch_all deploy_env, app
    unless rcs
      message = 'Unable to connect to Kubernetes, please try again later...'
      prompter.print message, :error
      abort
    end
    rc = rcs.first

    unless rc
      message = "Could not find a replication controller for the \"#{deploy_env}\" environment"
      prompter.print message, :error
      abort
    end

    # Prep deployment:
    # 1. Update image
    # 2. Update replica count
    # 3. Write out to a tmp file
    # 4. Replace the running controller
    #     - this will create 1 new pod with the updated code

    # We can get away with first since it is a single container pod
    container = rc.containers.first
    container['image'] = "#{config.container_app_image_path}:#{deploy_sha}"
    rc.increment_replica_count
    rc.update

    # Get a list of pods for the RC, this must be done pre-change
    pods = Keel::GCloud::Kubernetes::Pod.fetch_all deploy_env, app
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
      new_pods = Keel::GCloud::Kubernetes::Pod.fetch_all deploy_env, app

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
    config    = Keel::GCloud::Config.new

    if config.executable_missing?
      message = 'Install Google Cloud command line tools'
      message += "\n"
      message += 'See: https://cloud.google.com/sdk/'

      abort message.red
    end
  end

  task :check_configuration do
    config    = Keel::GCloud::Config.new

    if config.system_configured?
      abort 'App appears to already be configured on your system.'.green
    end
  end

  task :install_k8s do
    prompter  = Keel::GCloud::Prompter.new
    prompter.print 'Install Kubernetes', :info
    Keel::GCloud::Component.install_k8s
  end

  task :authenticate_k8s do
    prompter  = Keel::GCloud::Prompter.new
    prompter.print 'Pulling Kubernetes auth configuration', :info
    auth = Keel::GCloud::Auth.new config: config
    auth.authenticate_k8s
  end

  task :gcloud_auth do
    prompter  = Keel::GCloud::Prompter.new
    prompter.print 'Authenticating with Google Cloud', :info
    Keel::GCloud::Auth.authenticate
  end

  task :update_tools do
    prompter  = Keel::GCloud::Prompter.new
    prompter.print 'Updating tools', :info
    Keel::GCloud::Component.update
  end

  task :set_gcloud_properties do 
    config    = Keel::GCloud::Config.new
    prompter  = Keel::GCloud::Prompter.new
    prompter.print 'Setting gcloud properties', :info
    config.set_properties
  end

  desc 'Pulls logs for a given environment'
  task :logs, [:environment] do |_, args|
    prompter  = Keel::GCloud::Prompter.new
    config    = Keel::GCloud::Config.new
    app       = config.app_name

    # Fetch namespaces from k8s
    namespaces = Keel::GCloud::Kubernetes::Namespace.fetch_all
    unless namespaces
      message = 'Unable to connect to Kubernetes, please try again later...'
      prompter.print message, :error
      abort
    end

    # Prompt the user for the env and to log and whether to tail the logs
    deploy_env    = prompter.prompt_for_namespace namespaces, args[:environment]
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
