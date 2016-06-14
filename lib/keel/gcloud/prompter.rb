require 'inquirer'
require 'colorize'

module Keel::GCloud
  class Prompter
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

    def prompt_for_namespace namespaces, default
      return default unless default.blank?

      options = namespaces.map { |namespace| namespace.name }
      index = Ask.list 'Please choose an environment (destination)', options
      options[index]
    end

    def prompt_for_sha default
      return default unless default.blank?

      # Get current git SHA
      current_sha = `git rev-parse --short HEAD`.lines.first.split(' ')[0]
      Ask.input 'Git SHA', default: current_sha
    end

    def prompt_for_database_url default
      return default unless default.blank?

      Ask.input 'Database URL'
    end

    def prompt_for_secret_key default
      return default unless default.blank?

      Ask.input 'Secret key'
    end

    def prompt_for_tailing_logs
      Ask.confirm "To tail or not to tail? (ie: -f, --follow[=false]: Specify if the logs should be streamed.)", default: true
    end
  end
end
