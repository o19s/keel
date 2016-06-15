namespace :keel do
  desc 'Deploy the specified SHA to a given environment'
  task :deploy, [:environment, :deploy_sha] do |_, args|
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

    # Prompt the user for the env and git commit to deploy
    deploy_env  = prompter.prompt_for_namespace namespaces, args[:environment]
    deploy_sha  = prompter.prompt_for_sha args[:deploy_sha]

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
    container['image'] = "gcr.io/quepid-1051/quails:#{deploy_sha}"
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
    notifier = Keel::GCloud::Notifier::NewRelic.new env: deploy_env, sha: deploy_sha
    notifier.notify

    prompter.print 'Deployment complete', :success
  end

  desc 'Configures the local machine for communication with gcloud and k8s'
  task :setup do |_|
    prompter  = Keel::GCloud::Prompter.new
    config    = Keel::GCloud::Config.new

    if config.executable_missing?
      message = 'Install Google Cloud command line tools'
      message += "\n"
      message += 'See: https://cloud.google.com/sdk/'

      abort message.red
    end

    if config.system_configured?
      abort 'App appears to already be configured on your system.'.green
    end

    prompter.print 'Updating tools', :info
    Keel::GCloud::Component.update

    prompter.print 'Authenticating with Google Cloud', :info
    Keel::GCloud::Auth.authenticate

    prompter.print 'Install Kubernetes', :info
    Keel::GCloud::Component.install_k8s

    prompter.print 'Setting gcloud properties', :info
    config.set_properties

    prompter.print 'Pulling Kubernetes auth configuration', :info
    auth = Keel::GCloud::Auth.new config: config
    auth.authenticate_k8s
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
