module Keel
  class Railtie < Rails::Railtie # :nodoc: all
    rake_tasks do
      load 'tasks/keel.rake'
    end
  end
end
