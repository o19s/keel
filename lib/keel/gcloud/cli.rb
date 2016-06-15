module Keel::GCloud
  #
  # A helper class to run system commands and handle interrupts.
  #
  class Cli
    def execute command
      begin
        `#{command}`
      rescue Interrupt
        puts 'Task interrupted.'
      end
    end

    def system_call command
      begin
        system command
      rescue Interrupt
        puts 'Task interrupted.'
      end
    end
  end
end
