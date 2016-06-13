module Kitchen
  module Driver
    module VMMUtils

      ERROR_REGEXP  = /===Begin-Error===(.+?)===End-Error===/m
      OUTPUT_REGEXP = /===Begin-Output===(.+?)===End-Output===/m

      def execute(path, options)
        r = execute_powershell(path, options)
        if r.error?
          raise ("Powershell failed, #{path}:#{r.stderr}")
        end

        # We only want unix-style line endings within Vagrant
        r.stdout.gsub!("\r\n", "\n")
        r.stderr.gsub!("\r\n", "\n")

        error_match  = ERROR_REGEXP.match(r.stdout)
        output_match = OUTPUT_REGEXP.match(r.stdout)

        if error_match
          data = JSON.parse(error_match[1])

          # We have some error data.
          raise "#{path}:#{data["error"]}"
        end

        # Nothing
        return nil if !output_match
        return JSON.parse(output_match[1])
      end

      def execute_powershell(path, options = {})
        lib_path = Pathname.new(File.expand_path("../../../../support", __FILE__))
        script_path = lib_path.join(path).to_s.gsub("/", "\\")
        ps_options = ''
        options.each do |key, value|
          unless value.nil?
            ps_options += " -#{key} \"#{value}\""
          end
        end
        #
        stdout_stream_reader = StreamReader.new do |line|
          info(line)
        end
        ps_run = Mixlib::ShellOut.new("powershell.exe -File #{script_path} #{ps_options} -ErrorAction Stop")
        debug("Command: #{ps_run.command}")
        ps_run.live_stdout = stdout_stream_reader
        ps_run.run_command
        return ps_run
      end

      # for powershell stdout read
      class StreamReader
          require 'stringio'

          def initialize(&block)
            @block = block
            @buffer = StringIO.new
            @buffer.sync = true if @buffer.respond_to?(:sync)
          end

          def <<(chunk)
            overflow = ''

            @buffer.write(chunk)
            @buffer.rewind

            @buffer.each_line do |line|
              if line.match(/\r?\n/)
                @block.call(line.strip)
              else
                overflow = line
              end
            end

            @buffer.truncate(@buffer.rewind)
            @buffer.write(overflow)
          end
      end # StreamReader

    end # module VMMUtils
  end # module Driver
end # module Kitchen
