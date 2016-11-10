require 'singleton'

module Cagnut
  class JobManage
    include Singleton
    extend Forwardable
    def_delegators :'Cagnut::Configuration.base', :sample_name, :jobs_dir, :cluster

    class << self
      def submit job_script, job_name, opts
        instance.submit job_script, job_name, opts
      end

      def run_local
        instance.run_local
      end
    end

    def submit job_script, job_name, opts
      command = full_command job_script, job_name, opts
      export_command command
      puts command
    end

    def full_command job_script, job_name, opts
      return super if defined?(super) && !run_local?
      local job_script
    end

    def run_local?
      cluster.blank? || cluster['system'] == 'Local'
    end

    def export_command command
      file = File.join jobs_dir, "submit_command_#{sample_name}.jobs"
      File.open(file, 'a') do |f|
        f.puts <<-BASH.strip_heredoc
          #{command}
          #{wait_local}
        BASH
      end
      File.chmod(0700, file)
    end

    def local job_script
      %(nohup #{jobs_dir}/#{job_script}.sh \
      > #{jobs_dir}/#{job_script}.std \
      2>#{jobs_dir}/#{job_script}.err &)
    end

    def run_local
      return unless run_local?
      %(& echo $! >> #{jobs_dir}/submit_job_#{sample_name}.ids
        wait $!)
    end

    def wait_local
      return unless run_local?
      'wait $!'
    end
  end
end
