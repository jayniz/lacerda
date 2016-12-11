require 'ffi'

# We used redsnow gem before to parse mson to an AST json
# Resdnow used under the hood drafter. As redsnow is deprecated
# we have to implement our own binding to drafter.
# For reference, This is the old c method signature in drafter:
#
# https://github.com/apiaryio/drafter/commit/bcd6201eba34c6212112051e9111aeecd5a22a48
#
#     SC_API int drafter_c_parse(const char* source, sc_blueprint_parser_options options, char** result) 
#
# Which was bound in ruby like this https://github.com/apiaryio/redsnow/blob/master/lib/redsnow/binding.rb
#
#     enum :option, [:render_descriptions_option, :require_blueprint_name_option, :export_sourcemap_option]
#     attach_function('drafter_c_parse', 'drafter_c_parse', [:string, :option, :pointer], :int)
#
# And then called in our code like this
#     parse_result = FFI::MemoryPointer.new :pre_blueprint_name_optioneinter
#     RedSnow::Binding.drafter_c_parse(mson, 0, parse_result)
#     parse_result = parse_result.get_pointer(0)

module Lacerda
  module Drafter
    extend FFI::Library

    prefix = FFI::Platform.mac? ? '' : 'lib.target/'

    ffi_lib File.expand_path("../../../ext/drafter/build/out/Release/#{prefix}libdrafter.#{FFI::Platform::LIBSUFFIX}", __FILE__)

    enum :drafter_format, [:DRAFTER_SERIALIZE_YAML, :DRAFTER_SERIALIZE_JSON]

    class DrafterOptions < FFI::Struct
      layout :sourcemap, :bool,
             :format, :drafter_format
    end
    # Options that we pass to drafter normally.
    def self.options
      DrafterOptions.new.tap do |drafter_options_struct|
        # serialize as json(1), as the default is yaml(0)
        drafter_options_struct[:format] = 1
        drafter_options_struct[:sourcemap] = false
      end
    end

    #  Attached function:
    #  https://github.com/apiaryio/drafter/blob/0f485b647e71780659d1d4e42c402d60a9dd1507/src/drafter.cc
    #  DRAFTER_API int drafter_parse_blueprint_to(const char* source, char **out, const drafter_options options)
    attach_function :drafter_parse_blueprint_to, [:string, :pointer, DrafterOptions.by_value], :int
  end
end
