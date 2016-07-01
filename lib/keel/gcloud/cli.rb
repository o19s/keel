require 'open3'
module Keel::GCloud
  #
  # A helper class to run system commands and handle interrupts.
  #
  class Cli
    def execute command
      begin
        out = ""
        Open3.popen3(command) do |stdout, stderr, stdin, thread|
          # TODO do smarter things with status and stdout
          while line=stderr.gets do
            out += line
            print '.'
          end
          print "\n"
          raise "error while processing. " + out unless thread.value.success?
          return out
        end
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
