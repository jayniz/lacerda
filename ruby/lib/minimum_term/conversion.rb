require 'open3'

module MinimumTerm
  class Conversion
    def self.mson_to_json_schema(filename)
      input = filename
      output = filename.gsub(/\.\w+$/, '.json')

      cmd = "drafter -u -f json -o #{Shellwords.escape(output)} #{Shellwords.escape(input)}"
      stdin, stdout, status = Open3.capture3(cmd)

      {
        cmd: cmd,
        stdin: stdin,
        stdout: stdout,
        status: status
      }
    end
  end
end
