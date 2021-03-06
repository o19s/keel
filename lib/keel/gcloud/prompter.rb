require 'inquirer'
require 'colorize'

module Keel::GCloud
  #
  # A helper to output to the command line and prompt the user for input.
  #
  class Prompter
    #
    # Prints the message with coloring based on the level param.
    #
    # @param message [String] the message to print
    # @param level [String, nil] the level that determines the color
    #
    def print message, level=nil
      case level
      when :success
        puts message.green
      when :error
        puts message.red
      when :info
        puts message.blue
      else
        puts message
      end
    end

    #
    # Prompts the user to select the namespace from a list.
    # If a default is provided it returns that instead.
    #
    # @param namespaces [Array<Namespace>] the array of namespaces to choose from
    # @param default [String, nil] the default choice
    #
    def prompt_for_namespace namespaces, default=nil
      return default unless default.nil? || default.empty?

      options = namespaces.map { |namespace| namespace.name } - ['kube-system']
      if options.count > 1
        index = Ask.list 'Please choose an environment (destination)', options
        options[index]
      else
        options[0]
      end
    end

    #
    # Prompts the user to provide a label.  Defaults to the current git branch shortened SHA.
    # If a default is provided it returns that instead.
    #
    # @param default [String, nil] the default choice
    #
    def prompt_for_label default=nil
      return default unless default.nil? || default.empty?

      # Get current git SHA
      current_sha = `git rev-parse --short HEAD`.lines.first.split(' ')[0]
      Ask.input 'Image Label (defaults to Git SHA)', default: current_sha
    end

    #
    # Prompts the user to provide a datbase URL.
    # If a default is provided it returns that instead.
    #
    # @param default [String, nil] the default choice
    #
    def prompt_for_database_url default=nil
      return default unless default.nil? || default.empty?

      Ask.input 'Database URL'
    end

    #
    # Prompts the user to provide a secret key.
    # If a default is provided it returns that instead.
    #
    # @param default [String, nil] the default choice
    #
    def prompt_for_secret_key default=nil
      return default unless default.nil? || default.empty?

      Ask.input 'Secret key'
    end

    #
    # Prompts the user to choose if they want to tail the logs or not.
    #
    def prompt_for_tailing_logs
      Ask.confirm "To tail or not to tail? (ie: -f, --follow[=false]: Specify if the logs should be streamed.)", default: true
    end
  end
end
