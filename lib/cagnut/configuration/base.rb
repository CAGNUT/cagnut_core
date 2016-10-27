require 'singleton'

module Cagnut
  module Configuration
    class Base
      include Singleton
      attr_accessor :ref_fasta, :data_type, :snpdb, :sample_name, :jobs_dir, :java_path,
                    :prefix_name, :target_flanks_file, :dbsnp_ref_indels, :cluster,
                    :target, :magic28, :dodebug, :seqs_path, :pipeline_name

      class << self
        def load config
          instance.load config
        end
      end

      def load config
        @config = config
        attributes.each do |name, value|
          send "#{name}=", value if respond_to? "#{name}="
        end
      end

      def attributes
        {
          prefix_name: @config['prefix_name'],
          sample_name: @config['sample']['name'],
          dodebug: @config['dodebug'],
          java_path: @config['tools']['java'],
          ref_fasta: @config['refs']['ref_fasta'],
          snpdb: @config['refs']['dbsnp']['ref'],
          dbsnp_ref_indels: @config['refs']['dbsnp']['indels'],
          target: @config['refs']['targets_file'],
          target_flanks_file: @config['refs']['target_flanks_file'],
          magic28: '1f8b08040000000000ff0600424302001b0003000000000000000000',
          seqs_path: @config['sample']['seqs_path'],
          data_type: @config['info']['data_type'],
          jobs_dir: @config['sample']['jobs'],
          cluster: @config['cluster']
        }
      end
    end
  end
end
