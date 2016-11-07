module Cagnut
  module Pipeline
    class Base

      class << self
        attr_reader :pipelines

        def register klass
          @pipelines ||= []
          @pipelines << klass
        end
      end

      def start *args
        ENV['BUNDLE_GEMFILE'] ||= File.expand_path('./Gemfile', Dir.pwd)
        require 'bundler/setup'
        Bundler.require(:default)

        options = pepeline_opts
        run_filter options[:run] if options[:run]
        config_name = get_config_name options[:run]
        config = Cagnut.load_config config_name, options
        config['dodebug'] = options[:debug]
        config['samples'].each do |sample|
          config['sample'] = sample
          run_pipeline options[:run] if options[:run]
          execute_command config, sample unless options[:debug]
        end
      end

      private

      def get_config_name pipeline_names
        abort 'Did not assign pipeline to run' if pipeline_names.blank?
        selected = self.class.pipelines.find do |p|
          if p.try(:pipeline_names)
            !( pipeline_names & p.pipeline_names ).empty?
          elsif p.try(:pipeline_name)
            pipeline_names.include? p.pipeline_name
          else
            puts "Can not find tools yml"
            exit
          end
        end
        selected.config_name
      end

      def run_filter names
        puts 'Pipeline Conflict!'
        exit
      end

      def run_pipeline pipelines, job_name = '', filename = ''
        pipelines.sort.each do |pipeline|
          job_name, filename = send "pipeline_#{pipeline}", { job_name: job_name, filename: filename }
        end
      end

      def execute_command config, sample
        job = fork do
          exec "#{sample['jobs']}/submit_command_#{sample['name']}.jobs"
        end
        Process.detach(job)
      end

      def pepeline_opts options = {}
        OptionParser.new do |opts|
          opts.banner = 'Usage: example.rb [options]'
          opts.on('-d', '--debug', 'Dodebug') do
            options[:debug] = true
          end
          opts.on('-c', '--config yaml', 'Cagnut Config YAML') do |c|
            options[:config] = c
          end
          opts.on('-n', '--no_check_tools', 'Not Check Tools') do
            options[:no_check] = true
          end
          opts.on('-r', '--run draw1,draw2,draw3 or xyz', Array, 'run: draw1,draw2,draw3 or xyz') do |r|
            options[:run] = r
          end
          opts.on('-p', '--parameter yaml', 'Cagnut Parameter Config YAML') do |p|
            options[:params] = p
          end
          opts.on('-l', '--list', 'Pipeline List') do
            list = self.class.pipelines.map do |pipeline|
              pipeline.try(:pipeline_names) || pipeline.try(:pipeline_name)
            end
            puts "\s\s#{list.join("\n\s\s")}"
          end
          opts.on('-h', '--help', 'Help') do
            puts "Help"
          end
        end.parse!
        return options
      end

    end
  end
end
