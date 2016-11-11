module Cagnut
  class NewProject < Thor

    include Thor::Actions
    source_root Cagnut.root.join('templates')

    desc 'new NAME project', 'new NAME project'
    def new *args
      if args.size >= 1
        if !args.first.start_with? '-'
          name = args.shift
        elsif !args.last.start_with? '-'
          name = args.pop
        else
          puts "please use `cagnut new <name>`\n"
          exit(1)
        end
      else
        puts "please use `cagnut new <name>`\n"
        exit(1)
      end
      new_project name, project_opts
    end

    private

    def new_project name, options
      empty_directory name
      copy_file 'Gemfile', "#{name}/Gemfile"
      inside name, verbose: true do
        create_file '.ruby-version', '2.3.1'
        append_to_file 'Gemfile', "gem 'cagnut_cluster'\n" if options[:cluster]
        append_pipeline_gems_to_gemfile options[:pipelines]
        bundle 'install'
      end
      copy_file 'system.yml', "#{name}/system.yml"
      load_bundle_env name
      after_new_project name
      generate_pipeline_tools_config name, options[:pipelines], options[:cluster]
      append_pipeline_dependency_gems_to_gemfile name, options[:pipelines]
    end

    def add_queue_setting name, pipeline
    end

    def load_bundle_env name
      ENV['BUNDLE_GEMFILE'] ||= File.expand_path("#{name}/Gemfile", Dir.pwd)
      require 'bundler/setup'
      Bundler.require(:default)
    end

    def append_pipeline_gems_to_gemfile pipelines
      return if pipelines.blank?
      pipelines.each do |pipeline_name|
        append_to_file 'Gemfile', "gem 'cagnut_pipeline_#{pipeline_name}'\n"
      end
    end

    def append_pipeline_dependency_gems_to_gemfile folder, pipelines
      inside folder, verbose: true do
        pipelines.each do |pipeline_name|
          gems = send "#{pipeline_name}_pipeline_dependency_gems"
          gems.each { |gem_name| append_to_file 'Gemfile', "gem #{gem_name}\n" }
        end
        bundle 'update'
      end
    end

    def generate_pipeline_tools_config name, pipelines, cluster=nil
      return if pipelines.blank?
      pipelines.each do |pipeline_name|
        send "copy_#{pipeline_name}_tools_config", name
        add_queue_setting name, pipeline_name if cluster
      end
    end

    def after_new_project name
    end

    def project_opts options = {}
      OptionParser.new do |opts|
        opts.banner = 'Usage: example.rb [options]'
        opts.on('-c', '--cluster', 'Cluster') do
          options[:cluster] = true
        end
        opts.on('-p', '--pipelines draw', Array, 'Pipelines') do |p|
          options[:pipelines] = p
        end
      end.parse!
      return options
    end

    def bundle command
      say_status :run, "bundle #{command}"
      _bundle = Gem.bin_path('bundler', 'bundle')
      require 'bundler'
      Bundler.with_clean_env do
        full_command = %Q["#{Gem.ruby}" "#{_bundle}" #{command}]
        if options[:quiet]
          system(full_command, out: File::NULL)
        else
          system(full_command)
        end
      end
    end

  end
end
