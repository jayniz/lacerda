require 'fileutils'
require 'open3'
require 'lacerda/conversion/apiary_to_json_schema'
require 'lacerda/conversion/error'
require 'lacerda/drafter'
require 'redsnow'
require 'colorize'

module Lacerda
  module Conversion
    def self.mson_to_json_schema(options)
      filename = options.fetch(:filename)
      begin
        mson_to_json_schema!(
          filename: filename,
          keep_intermediary_files: options.fetch(:keep_intermediary_files, false)
        )
        puts "OK ".green + filename if options.fetch(:verbose, true)
        true
      rescue
        puts "ERROR ".red + filename if options.fetch(:verbose, true)
        false
      end
    end

    def self.mson_to_json_schema!(options, old = false)
      filename = options.fetch(:filename)

      # For now, we'll use the containing directory's name as a scope
      service_scope = File.dirname(filename).split(File::SEPARATOR).last.underscore

      # Parse MSON to an apiary blueprint AST
      # (see https://github.com/apiaryio/api-blueprint)
      ast_file = mson_to_ast_json(filename)

      # Pluck out Data structures from it
      data_structures = data_structures_from_blueprint_ast(ast_file, old)

      # Generate json schema from each contained data structure
      schema = {
        "$schema"     => "http://json-schema.org/draft-04/schema#",
        "title"       => service_scope,
        "definitions" => {},
        "type"        => "object",
        "properties"  => {},
      }

      basename = File.basename(filename)
      if !basename.end_with?("publish.mson") and !basename.end_with?("consume.mson")
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
        id = old ? data['name']['literal'] : data['content'].first['meta']['id']
        json= DataStructure.new(id, data, nil).to_json
        member = json.delete('title')
        schema['definitions'][member] = json
        schema['properties'][member] = {"$ref" => "#/definitions/#{member}"}
      end

      # Write it in a file
      outfile = filename.gsub(/\.\w+$/, '.schema.json')
      File.open(outfile, 'w'){ |f| f.puts JSON.pretty_generate(schema) }

      # Clean up
      FileUtils.rm_f(ast_file) unless options.fetch(:keep_intermediary_files, false)
      true
    end

    def self.data_structures_from_blueprint_ast(filename, old)
      json = JSON.parse(open(filename).read)
      content = old ? json['ast']['content'].first : ['content'].first
      return [] if content.nil?
      return [] unless old || content.is_a?(Array)
      content['content'].first 
    end

    def self.mson_to_ast_json(filename, old = false)
      input = filename
      output = filename.gsub(/\.\w+$/, '.blueprint-ast.json')

      # Add Data Structure section automatically
      mson = open(input).read
      unless mson[/^\#[ ]*data[ ]+structure/i]
        mson = "# Data Structures\n#{mson}"
      end

      parse_result = FFI::MemoryPointer.new :pointer
      old ?  RedSnow::Binding.drafter_c_parse(mson, 0, parse_result) : Lacerda::Drafter.drafter_parse_blueprint_to(mson, parse_result, Lacerda::Drafter.options)
      pointer_to_file(parse_result, output)
      # TODO: FREE MEMORY FOR THE POINTER!
    end

    def self.pointer_to_file(parse_result, output)
      parse_result = parse_result.get_pointer(0)

      status = -1
      result = ''

      unless parse_result.null?
        status = 0
        result = parse_result.read_string
      end

      File.open(output, 'w'){ |f| f.puts(result)  }

      output
    end
  end
end
