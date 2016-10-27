module Cagnut
  module Configuration
    module Checks

      class Datasets
        attr_accessor :config

        def initialize config
          @config = config
        end

        def check config_name
          @config['prefix_name'] = "#{Cagnut.prefix_name}_#{config_name}"
          analysis_folder = create_analysis_folder config
          @config['samples'].each_with_index do |sample, index|
            setup_requirements sample, index, analysis_folder
          end
          @config
        end

        def create_analysis_folder config
          output_data_dir = dir_rm_slash @config['cagnut']['output_data_dir']
          analysis_folder = "#{output_data_dir}/#{config['prefix_name']}"
          FileUtils.mkdir_p "#{output_data_dir}/#{config['prefix_name']}"
          analysis_folder
        end

        def setup_requirements sample, index, analysis_folder
          puts "Dataset : #{sample['path']}"
          dir = "#{analysis_folder}/#{sample['name']}"
          FileUtils.mkdir_p dir unless Dir.exist?(dir)
          @config['samples'][index]['path'] = dir_rm_slash sample['path']
          FileUtils.mkdir_p "#{analysis_folder}/#{sample['name']}/jobs"
          @config['samples'][index]['jobs'] = "#{analysis_folder}/#{sample['name']}/jobs"
          FileUtils.mkdir_p "#{analysis_folder}/#{sample['name']}/tmp"
          @config['samples'][index]['tmp'] = "#{analysis_folder}/#{sample['name']}/tmp"
          # mysql_insert if options[:mysql]
          make_required_folders @config, sample, index, dir
          check_pu index
        end

        def make_required_folders config, sample, index, analysis_folder
        end

        def ln_seq_files_to_folder sample, qseq_path, fastq_path
          ln_seq_files sample, qseq_path, fastq_path
          check_datatype qseq_path, fastq_path
          check_ln_file sample, qseq_path, fastq_path
        end

        def check_ln_file sample, qseq_path, fastq_path
          fastq = Dir.glob("#{fastq_path}/*.fastq*")
          qseq = Dir.glob("#{qseq_path}/*")
          return unless (fastq + qseq).empty?
          abort "Not found #{sample['name']} files in fastq and qseq"
        end

        def ln_seq_files sample, seq_txt, fastq_file
          dir_present? sample['path']
          ln_seq_txt_file sample, seq_txt
          ln_fastq_file sample, fetch_flist(sample['path']), fastq_file
        end

        def dir_present? dataset
          return if Dir.exist?(dataset)
          puts "Error: Missing data directory #{@config['datasets']}"
          exit
        end

        def dir_rm_slash dir
          dir.gsub %r{/\z}, ''
        end

        def ln_seq_txt_file sample, qseq_dir
          files =
            Dir.glob("#{sample['path']}/*_sequence.txt*") + Dir.glob("#{sample['path']}/*_qseq.txt*")
          files.each do |f|
            `ln -s #{f} #{qseq_dir} 2>/dev/null` if f.match sample['name']
          end
        end

        def fetch_flist dir
          flist = Dir.glob("#{dir}/*.fastq*")
          return flist unless flist.empty?
          abort "No fastq found in #{dir}"
        end

        def ln_fastq_file sample, flist, fastq_dir
          if %w(ONEFASTQ ONEFASTQSE).include? @config['info']['data_type']
            files_to_much? flist
            file_type = link_name flist, sample['name']
            seq_file = "#{fastq_dir}/#{file_type}"
            `ln -s #{flist[0]} #{seq_file} 2>/dev/null` if flist[0].match sample['name']
          else
            flist.each do |f|
              next unless f.match sample['name']
              `ln -s #{f} #{fastq_dir} 2>/dev/null`
            end
          end
        end

        def link_name flist, sample_name
          if flist[0].match '.gz'
            "#{sample_name}_sequence.txt.gz"
          else
            "#{sample_name}_sequence.txt"
          end
        end

        def files_to_much? flist
          return unless flist.size > 1
          puts %(
            DATA_TYPE = #{@config['info']['data_type']} but more than one fastq found.
            Only the first would be processed.
            #{flist.inspect}
          )
        end

        def check_pu index
          @config['samples'][index]['pu'] ||= 'NA'
        end

        def check_datatype qseq_dir, fastq_dir
          @config['samples'].each_with_index do |sample, index|
            case @config['info']['data_type']
            when 'TILESQSEQ'
              file = "#{qseq_dir}/*.txt*"
              pattern = '.*s_\d+_1_(\d+).*'
              file_end = '.fastq'
            when 'TILESFASTQ'
              file = "#{fastq_dir}/*.fastq*"
              pattern = '(.*_R1_.*).fastq.*+'
              file_end = '.fastq'
            end
            @config['samples'][index]['seqs_path']= fetch_seqs Dir[file], file_end, pattern
          end
          @config
        end

        def fetch_seqs files_path, file_end, pattern
          files_path.map do |file|
            return file if File.basename(file, file_end).match(/#{pattern}/)
          end.flatten.compact
        end
      end

    end
  end
end
