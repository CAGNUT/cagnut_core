require 'yaml'
require 'forwardable'
require 'cagnut/configuration/base'
require 'cagnut/configuration/checks/tools'
require 'cagnut/configuration/checks/datasets'

module Cagnut
  module Configuration
    mattr_writer :base, :toolbox
    mattr_accessor :config, :params

    class << self
      def configure
        yield self
      end

      def params
        @params
      end

      def base
        @base ||= begin
          Cagnut::Configuration::Base.load(@config)
          Cagnut::Configuration::Base.instance
        end
      end

      def load_config config_name, options
        @config ||= check_and_load_yml fetch_system_config_path(options[:config])
        @params ||= check_and_load_yml fetch_tools_config_path(config_name, options[:params])
        config_check config_name, options[:not_check]
      end

      private

      def check_and_load_yml yml_path
        check_path yml_path
        puts "Using #{yml_path}"
        YAML.load_file yml_path
      end

      def check_path file
        return file if File.exist?(file)
        puts "No such File in: #{file}"
        exit
      end

      def fetch_system_config_path cfg_path=nil
        if !cfg_path.blank?
          cfg_path
        elsif Dir.entries(Dir.pwd).include? "system.yml"
          File.join(Dir.pwd, 'system.yml')
        else
          puts "Not Found system.yml in #{Dir.pwd}"
          exit
        end
      end

      def fetch_tools_config_path config_name, config_path=nil
        if !config_path.blank?
          config_path
        elsif Dir.entries(Dir.pwd).include? "#{config_name}_tools.yml"
          File.join(Dir.pwd, "#{config_name}_tools.yml")
        else
          puts "Not Found #{config_name}_tools.yml in #{Dir.pwd}"
          exit
        end
      end

      def config_check config_name, not_check=false
        tools_check unless not_check
        @config['pipeline_name'] = config_name
        @config = check_datasets config_name
      end

      def tools_check
        @tools = Cagnut::Configuration::Checks::Tools.new @config
        @tools.check
      end

      def check_datasets config_name
        @datasets = Cagnut::Configuration::Checks::Datasets.new @config
        @datasets.check config_name
      end

    end
  end
end
