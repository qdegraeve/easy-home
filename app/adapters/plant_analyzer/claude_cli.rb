require "base64"
require "json"
require "open3"
require "tmpdir"

module PlantAnalyzer
  # Runs Claude Code headless (`claude -p`) on the developer's Claude plan. The photos travel inside the message
  # (stream-json input), so the agent gets no tool at all: no file reading, no shell, no web, no MCP server. It runs
  # in an empty temporary directory, without shell, with a timeout. An analysis must answer with RESPONSE_SCHEMA; a
  # follow-up question gets plain text.
  class ClaudeCli
    TIMEOUT = 180 # seconds

    def initialize(executable: ENV.fetch("CLAUDE_BIN", "claude"), model: ENV.fetch("PLANT_ANALYSIS_MODEL", "sonnet"))
      @executable = executable
      @model = model
    end

    attr_reader :model

    def analyze(images:, text:)
      result = call_claude(images, text, SYSTEM_PROMPT, "--json-schema", RESPONSE_SCHEMA.to_json)
      result["structured_output"] || raise(Error, "claude gave no structured answer")
    end

    def answer(images:, text:)
      result = call_claude(images, text, FOLLOW_UP_PROMPT)
      result["result"].presence || raise(Error, "claude gave an empty answer")
    end

    private

    def call_claude(images, text, system_prompt, *extra_arguments)
      output = run(arguments(system_prompt) + extra_arguments, message(images, text))
      result = output.each_line.filter_map { |line| parse(line) }.find { |event| event["type"] == "result" }
      raise Error, "no result from claude" unless result
      raise Error, "claude failed: #{result["result"].to_s.truncate(200)}" if result["is_error"]

      result
    end

    def arguments(system_prompt)
      [
        @executable, "-p",
        "--input-format", "stream-json",
        "--output-format", "stream-json",
        "--verbose",
        "--tools", "",
        "--strict-mcp-config",
        "--disable-slash-commands",
        "--setting-sources", "",
        "--permission-mode", "dontAsk",
        "--no-session-persistence",
        "--model", @model,
        "--system-prompt", system_prompt
      ]
    end

    def message(images, text)
      content = images.map do |jpeg|
        { type: "image", source: { type: "base64", media_type: "image/jpeg", data: Base64.strict_encode64(jpeg) } }
      end
      { type: "user", message: { role: "user", content: content + [ { type: "text", text: } ] } }.to_json
    end

    def run(arguments, input)
      Dir.mktmpdir("plant-analysis") do |dir|
        Open3.popen3(*arguments, chdir: dir) do |stdin, stdout, stderr, wait_thread|
          output = Thread.new { stdout.read }
          errors = Thread.new { stderr.read }
          Thread.new { write(stdin, input) }
          wait_or_kill(wait_thread)
          check_exit(wait_thread.value, output.value, errors.value)
        end
      end
    rescue Errno::ENOENT
      raise Error, "claude is not installed"
    end

    # In a thread, so the timeout also covers a claude that never reads its input. A claude that exits early (expired
    # login, quota) closes the pipe: its own error message comes on stdout.
    def write(stdin, input)
      stdin.write(input)
    rescue Errno::EPIPE, IOError
      nil
    ensure
      stdin.close unless stdin.closed?
    end

    def wait_or_kill(wait_thread)
      return if wait_thread.join(TIMEOUT)

      Process.kill("KILL", wait_thread.pid)
      raise Error, "claude timed out after #{TIMEOUT} s"
    end

    # An error result still comes on stdout as a "result" event; only a crash without any output is fatal here.
    def check_exit(status, output, errors)
      return output if status.success? || output.present?

      raise Error, "claude exited with #{status.exitstatus}: #{errors.truncate(200)}"
    end

    def parse(line)
      JSON.parse(line)
    rescue JSON::ParserError
      nil
    end
  end
end
