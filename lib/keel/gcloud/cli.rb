module Keel::GCloud
  class Cli
    def execute command
      begin
        `#{command}`
      rescue Interrupt
        puts 'Task interrupted.'
      end
    end

    def call command
      begin
        system command
      rescue Interrupt
        puts 'Task interrupted.'
      end
    end
  end
end
