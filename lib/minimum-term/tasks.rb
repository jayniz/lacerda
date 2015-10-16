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

        desc "Transform all MSON files to JSON Schema using drafter"
        task :mson_to_json_schema, [:keep_intermediary_files] => :cleanup do |t, args|

          infrastructure = MinimumTerm::Infrastructure.new(File.expand_path("../contracts"))

          # For debugging it can be helpful to not clean up the
          # intermediary blueprint ast files.
          keep_intermediary_files = args.to_hash.values.include?('keep_intermediary_files')

          # If we were given files, just convert those
          files = ENV['FILES'].to_s.split(',')

          # OK then, we'll just convert all we find
          files = infrastructure.mson_files if files.blank?

          files.each do |file|
            if MinimumTerm::Conversion.mson_to_json_schema!(file, keep_intermediary_files)
              puts "✅  #{file}"
            else
              puts "❌  #{file}"
            end
          end
        end
      end
    end
  end
 end

MinimumTerm::Tasks.new.install_tasks