module Keel::GCloud
  class Cli
    def execute command
      begin
        `#{command}`
      rescue Interrupt
        puts 'Task interrupted.'
      end
    end

    def system command
      begin
        system command
      rescue Interrupt
        puts 'Task interrupted.'
      end
    end
  end
end
