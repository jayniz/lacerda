require 'fileutils'
require 'open3'
require 'lacerda/conversion/apiary_to_json_schema'
require 'lacerda/conversion/error'
require 'colorize'
require 'lounge_lizard'

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

    def self.mson_to_json_schema!(options)
      filename = options.fetch(:filename)

      # For now, we'll use the containing directory's name as a scope
      service_scope = File.dirname(filename).split(File::SEPARATOR).last.underscore

      # Parse MSON to an apiary blueprint AST
      # (see https://github.com/apiaryio/api-blueprint)
      ast_file = mson_to_ast_json(filename)
      raise_parsing_errors(filename, ast_file)

      # Pluck out Data structures from it
      data_structures = data_structures_from_blueprint_ast(ast_file)
 
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
        id = data['content'].first['meta']['id']
        json= DataStructure.new(id, data['content'], nil).to_json
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

    def self.raise_parsing_errors(mson_file, ast_file)
      parsing_errors = ast_parsing_errors(ast_file)
      return if parsing_errors.empty? 
      raise Error, parsing_errors.prepend("The following errors were found in #{mson_file}:").join("\n")
    end

    # The structure is of an AST is normally something like
    #    parseResult
    #      - category             # (meta => api)            It seems there is always only 1
    #        - category           # (meta => dataStructures) It seems there is always only 1
    #            - dataStructure  #                          Bunch of data structures
    #              . . .
    #            - dataStructure
    #              . . .
    #
    #      - annotation  # Bunch of annotations(errors/warnings
    #        . . .
    #      - annotation
    #        . . .
    def self.data_structures_from_blueprint_ast(filename)
      # The content of the ast parsing
      elements = parse_result_contents_from_ast_file(filename)

      # We keep the content of the categories only, they could be annotations otherwise
      result_categories = elements.select do |element|
        element['element'] == 'category'
      end.map { |category| category['content'] }.flatten 

      # From these categories we keep the 'dataStructures' category contents. 
      # If there could be other types, no idea ¯\_(ツ)_/¯
      data_structures_categories_contents = result_categories.select do |result_category|
        result_category['meta']['classes'].include?('dataStructures')
      end.map { |data_structures_category| data_structures_category['content'] }.flatten

      # From the contents of 'dataStructures' categories we keep
      # the 'dataStructure' elements. If there could be other types, 
      # no idea ¯\_(ツ)_/¯
      data_structures_categories_contents.select do |data_structures_content|
        data_structures_content['element'] == 'dataStructure'
      end
    end

    def self.ast_parsing_annotation_messages(filename, type)
      annotations = annotations_from_blueprint_ast(filename).select do |annotation|
        annotation['meta']['classes'].include?(type)
      end
      return [] if annotations.empty?
      annotations.map do |annotation|
        "#{type.capitalize} code #{annotation['attributes']['code']}: #{annotation['content']}"
      end
    end

    def self.mson_to_ast_json(filename)
      input = filename
      output = filename.gsub(/\.\w+$/, '.blueprint-ast.json')

      # Add Data Structure section automatically
      mson = open(input).read
      unless mson[/^\#[ ]*data[ ]+structure/i]
        mson = "# Data Structures\n#{mson}"
      end
      result = LoungeLizard.parse(mson)
      File.open(output, 'w'){ |f| f.puts(result)  }
      output
    end

    private_class_method def self.ast_parsing_errors(filename)
      ast_parsing_annotation_messages(filename, 'error')
    end

    # Reads a file containing a json representation of a blueprint AST file,
    # and returns the content of a parse result. 
    # It always returns an array.
    private_class_method def self.parse_result_contents_from_ast_file(filename)
      json = JSON.parse(open(filename).read)
      json&.dig('content') || []
    end

    private_class_method def self.annotations_from_blueprint_ast(filename)
      elements = parse_result_contents_from_ast_file(filename)
      elements.select { |element| element['element'] == 'annotation' }
    end
  end
end
