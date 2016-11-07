module Cagnut
  module Configuration
    module Checks
      class Tools
        attr_accessor :config, :check_completed, :java

        def initialize config
          @config = config
        end

        def check
          @check_completed = true
          check_each_tool
          result = @check_completed ? 'Completed!' : 'Failed!'
          puts "Check Tools: #{result}"
          exit unless @check_completed
        end

        def check_each_tool
          tools = @config['tools']
          refs = @config['refs']
          puts 'Start Checking...'
          check_execute_system
          check_ref_fasta refs['ref_fasta']
          check_java tools['java']
          check_r tools['R']
          check_tool tools, refs
        end

        def check_execute_system
          puts "Using Local System"
        end

        def check_tool tools_path, refs=nil
        end

        def check_tool_ver tool
          ver = yield if block_given?
          @check_completed = false if ver.blank?
          ver = ver.blank? ? 'Not Found' : ver.chomp!
          puts "Using #{tool} (#{ver})"
        end

        def check_java path
          failed = check_tool_ver 'Java' do
            `#{path} -version 2>&1| grep version | cut -f3 -d ' '` if path
          end
          @java = path unless failed
        end

        def check_r path
          check_tool_ver 'R' do
            `#{path} --version 2>&1 |grep ' version '| cut -f3 -d ' '` if path
          end
          check_r_libs path if path
        end

        def check_r_libs r_path
          %w(gplots ggplot2 reshape gsalib).each do |lib|
            check_tool_ver "R library: #{lib}" do
              `#{r_path}script -e 'packageVersion("#{lib}")' | cut -f2 -d ' '`
            end
          end
        end

        def check_ref_fasta ref_path
          puts 'Checking Reference Files...'
          return if File.exist?(ref_path)
          puts "\tReference not founded in #{ref_path}"
          @check_completed = false
        end
      end
    end
  end
end
