require 'open3'
module Keel::GCloud
  #
  # A helper class to run system commands and handle interrupts.
  #
  class Cli
    @@wait_sequence = %w[| / - \\]

    def execute command
      begin
        out = ""
        Open3.popen3(command) do |stdout, stderr, stdin, thread|
          show_wait_spinner{
            while line=stderr.gets do
              out += line
            end
          }
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

    # better wait cursors, thanks http://stackoverflow.com/questions/10262235/printing-an-ascii-spinning-cursor-in-the-console 
    def show_wait_spinner(fps=10)
      chars = %w[| / - \\]
      delay = 1.0/fps
      iter = 0
      spinner = Thread.new do
        while iter do  # Keep spinning until told otherwise
          print chars[(iter+=1) % chars.length]
          sleep delay
          print "\b"
        end
      end
      yield.tap{       # After yielding to the block, save the return value
        iter = false   # Tell the thread to exit, cleaning up after itself…
        spinner.join   # …and wait for it to do so.
      }                # Use the block's return value as the method's
    end
  end
end
