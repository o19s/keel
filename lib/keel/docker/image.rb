module Keel::Docker::Image
  def create(label, project_id, app_name)
    command = "docker build -t gcr.io/#{project_id}/#{app_name}:#{label} ." 
    Keel::GCloud::Cli.new.execute(command)
  end

  def push(label, project_id, app_name)
    command = "gcloud docker push gcr.io/#{project_id}/#{app_name}:#{label}"
    Keel::GCloud::Cli.new.execute(command)
  end
end