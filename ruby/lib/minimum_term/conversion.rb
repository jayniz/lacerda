require 'fileutils'
require 'open3'
require 'minimum_term/conversion/apiary_to_json_schema'

module MinimumTerm
  module Conversion
    def self.mson_to_json_schema(filename, keep_intermediary_files = false)

      # Parse MSON to an apiary AST
      # (see https://github.com/apiaryio/api-blueprint/wiki/API-Blueprint-Map)
      to_ast = mson_to_ast_json(filename)
      return false unless to_ast[:status] == 0

      # Pluck out Data structures from it
      data_structures = data_structures_from_apiary_ast(to_ast[:outfile])

      # Generate json schema from each contained data structure
      json_schemas = data_structures.map do |data|
        DataStructure.new(data).to_json
      end

      # Write it in a file
      outfile = filename.gsub(/\.\w+$/, '.schemas.json')
      File.open(outfile, 'w'){ |f| f.puts JSON.pretty_generate(json_schemas) }

      # Clean up
      FileUtils.rm(to_ast[:outfile]) unless keep_intermediary_files
      true
    end

    def self.data_structures_from_apiary_ast(filename)
      JSON.parse(open(filename).read)['content'].first['content']
    end

    def self.mson_to_ast_json(filename)
      input = filename
      output = filename.gsub(/\.\w+$/, '.apiary-ast.json')

      cmd = "drafter -u -f json -o #{Shellwords.escape(output)} #{Shellwords.escape(input)}"
      stdin, stdout, status = Open3.capture3(cmd)

      {
        cmd: cmd,
        outfile: output,
        stdin: stdin,
        stdout: stdout,
        status: status
      }
    end
  end
end
