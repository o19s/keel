module Keel
  class Railtie < Rails::Railtie
    rake_tasks do
      load 'tasks/keel.rake'
    end
  end
end
