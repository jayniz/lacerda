require 'fileutils'
require 'open3'
require 'minimum-term/conversion/apiary_to_json_schema'
require 'minimum-term/conversion/error'

module MinimumTerm
  module Conversion
    def self.mson_to_json_schema(filename:, keep_intermediary_files: false, verbose: false)
      begin
        mson_to_json_schema!(filename: filename, keep_intermediary_files: keep_intermediary_files, verbose: verbose)
        puts "OK ".green + filename if verbose
        true
      rescue
        puts "ERROR ".red + filename if verbose
        false
      end
    end

    def self.mson_to_json_schema!(filename:, keep_intermediary_files: false, verbose: true)

      # For now, we'll use the containing directory's name as a scope
      service_scope = File.dirname(filename).split(File::SEPARATOR).last.underscore

      # Parse MSON to an apiary blueprint AST
      # (see https://github.com/apiaryio/api-blueprint/wiki/API-Blueprint-Map)
      to_ast = mson_to_ast_json(filename)
      raise Error, "Error: #{to_ast}" unless to_ast[:status] == 0

      # Pluck out Data structures from it
      data_structures = data_structures_from_blueprint_ast(to_ast[:outfile])

      # Generate json schema from each contained data structure
      schema = {
        "$schema"     => "http://json-schema.org/draft-04/schema#",
        "title"       => service_scope,
        "definitions" => {},
        "type"        => "object",
        "properties"  => {},
      }

      # The scope for the data structure is the name of the service
      # publishing the object. So if we're parsing a 'consume' schema,
      # the containing objects are alredy scoped (because a consume
      # schema says 'i consume object X from service Y'.
      basename = File.basename(filename)
      if basename.end_with?("publish.mson")
        data_structure_autoscope = service_scope
      elsif basename.end_with?("consume.mson")
        data_structure_autoscope = nil
      else
        raise Error, "Invalid filename #{basename}, can't tell if it's a publish or consume schema"
      end

      # The json schema we're constructing contains every known
      # object type in the 'definitions'. So if we have definitions for
      # the objects User, Post and Tag, the schema will look like this:
      #
      # {
      #   "$schema": "..."
      #
      #   "definitions": {
      #     "user": { "type": "object", "properties": { ... }}
      #     "post": { "type": "object", "properties": { ... }}
      #     "tag":  { "type": "object", "properties": { ... }}
      #   }
      #
      #   "properties": {
      #     "user": "#/definitions/user"
      #     "post": "#/definitions/post"
      #     "tag":  "#/definitions/tag"
      #   }
      #
      # }
      #
      # So when testing an object of type `user` against this schema,
      # we need to wrap it as:
      #
      # {
      #   user: {
      #     "your": "actual",
      #     "data": "goes here"
      #     }
      # }
      #
      data_structures.each do |data|
        schema_data = data['content'].select{|d| d['element'] == 'object' }.first
        id = schema_data['meta']['id']
        json= DataStructure.new(id, schema_data, data_structure_autoscope).to_json
        member = json.delete('title')
        schema['definitions'][member] = json
        schema['properties'][member] = {"$ref" => "#/definitions/#{member}"}
      end

      # Write it in a file
      outfile = filename.gsub(/\.\w+$/, '.schema.json')
      File.open(outfile, 'w'){ |f| f.puts JSON.pretty_generate(schema) }

      # Clean up
      FileUtils.rm_f(to_ast[:outfile]) unless keep_intermediary_files
      true
    end

    def self.data_structures_from_blueprint_ast(filename)
      c = JSON.parse(open(filename).read)['content'].first
      return [] unless c
      c['content']
    end

    def self.mson_to_ast_json(filename)
      input = filename
      output = filename.gsub(/\.\w+$/, '.blueprint-ast.json')

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
