require 'fileutils'

module MinimumTerm
  class Tasks
    include Rake::DSL if defined? Rake::DSL

    def install_tasks
      namespace :minimum_term do
        desc "Clean up intermediary json files"
        task :cleanup do
          path = File.expand_path("../contracts")
          files = Dir.glob(File.join(path, "/**/*.schema.json")) +
                  Dir.glob(File.join(path, "/**/*.blueprint-ast.json"))
          files.each do |file|
            FileUtils.rm_f(file)
          end
        end

        desc "Transform all MSON files in DATA_DIR to JSON Schema using drafter"
        task :mson_to_json_schema, [:keep_intermediary_files] => :cleanup do |t, args|
          if ENV['DATA_DIR'].blank?
            puts "Please set DATA_DIR for me to work in"
            exit(-1)
          end

          data_dir = File.expand_path(ENV['DATA_DIR'])
          unless Dir.exist?(data_dir)
            puts "Not such directory: #{data_dir}"
            exit(-1)
          end

          # For debugging it can be helpful to not clean up the
          # intermediary blueprint ast files.
          keep_intermediary_files = args.to_hash.values.include?('keep_intermediary_files')

          # If we were given files, just convert those
          files = ENV['FILES'].to_s.split(',')

          # OK then, we'll just convert all we find
          files = Dir.glob(File.join(data_dir, '**/*.mson')) if files.empty?

          # That can't be right
          if files.empty?
            puts "No FILES given and nothing found in #{data_dir}"
            exit(-1)
          end

          # Let's go
          puts "Converting #{files.length} files:"

          ok = true
          files.each do |file|
            ok = ok && MinimumTerm::Conversion.mson_to_json_schema(
              filename: file,
              keep_intermediary_files: keep_intermediary_files,
              verbose: true)
          end

          exit(-1) unless ok
        end
      end
    end
  end
 end

MinimumTerm::Tasks.new.install_tasks
