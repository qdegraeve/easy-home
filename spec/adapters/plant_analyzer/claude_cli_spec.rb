require "rails_helper"

# The real `claude` is never called: a fake executable records its arguments, input and working directory, and
# prints the events the real CLI prints.
RSpec.describe PlantAnalyzer::ClaudeCli do
  let(:dir) { Pathname(Dir.mktmpdir("fake-claude")) }
  let(:executable) { dir.join("claude") }
  let(:answer) { FakePlantAnalyzer::ANSWER }
  let(:result_event) { { type: "result", subtype: "success", is_error: false, structured_output: answer } }

  after { FileUtils.remove_entry(dir) }

  def fake_claude(body)
    executable.write("#!/bin/sh\n#{body}\n")
    executable.chmod(0o755)
    described_class.new(executable: executable.to_s, model: "sonnet")
  end

  def printing(*events)
    lines = events.map { |event| event.to_json.shellescape }.join(" ")
    fake_claude(<<~SH)
      printf '%s\\n' "$@" > #{dir.join("args")}
      pwd > #{dir.join("cwd")}
      cat > #{dir.join("stdin")}
      for line in #{lines}; do echo "$line"; done
    SH
  end

  it "sends the photos inside the message, with no tool at all, and returns the structured answer" do
    cli = printing({ type: "system", subtype: "init", tools: [ "StructuredOutput" ] }, result_event)

    expect(cli.analyze(images: [ "JPEG-1", "JPEG-2" ], text: "Plant: Citronnier.")).to eq(answer.as_json)

    args = dir.join("args").read.split("\n")
    expect(args).to include("-p", "--strict-mcp-config", "--disable-slash-commands", "--no-session-persistence")
    expect(args.each_cons(2).to_a).to include(
      [ "--tools", "" ], [ "--input-format", "stream-json" ], [ "--permission-mode", "dontAsk" ],
      [ "--setting-sources", "" ], [ "--model", "sonnet" ], [ "--json-schema", PlantAnalyzer::RESPONSE_SCHEMA.to_json ]
    )
    expect(args).to include("--system-prompt")
    expect(dir.join("args").read).to include(PlantAnalyzer::SYSTEM_PROMPT.strip)

    content = JSON.parse(dir.join("stdin").read).dig("message", "content")
    expect(content.map { |block| block["type"] }).to eq(%w[image image text])
    expect(Base64.decode64(content.first.dig("source", "data"))).to eq("JPEG-1")
    expect(content.last["text"]).to eq("Plant: Citronnier.")
  end

  it "runs in an empty temporary directory, removed afterwards" do
    printing(result_event).analyze(images: [], text: "x")

    cwd = dir.join("cwd").read.strip
    expect(cwd).to include("plant-analysis")
    expect(File.exist?(cwd)).to be(false)
  end

  it "raises when claude reports an error (expired login, quota)" do
    cli = printing({ type: "result", is_error: true, result: "Failed to authenticate: OAuth session expired" })

    expect { cli.analyze(images: [], text: "x") }
      .to raise_error(PlantAnalyzer::Error, /Failed to authenticate/)
  end

  it "raises when there is no structured answer or no result at all" do
    expect { printing(result_event.merge(structured_output: nil)).analyze(images: [], text: "x") }
      .to raise_error(PlantAnalyzer::Error, "claude gave no structured answer")
    expect { printing({ type: "system" }).analyze(images: [], text: "x") }
      .to raise_error(PlantAnalyzer::Error, "no result from claude")
  end

  it "raises when claude crashes without output" do
    cli = fake_claude("echo boom >&2; exit 3")

    expect { cli.analyze(images: [], text: "x") }.to raise_error(PlantAnalyzer::Error, "claude exited with 3: boom\n")
  end

  it "kills claude after the timeout" do
    stub_const("#{described_class}::TIMEOUT", 0.2)
    cli = fake_claude("exec tail -f /dev/null")

    expect { cli.analyze(images: [], text: "x") }.to raise_error(PlantAnalyzer::Error, /timed out/)
  end

  it "raises when claude is not installed" do
    cli = described_class.new(executable: dir.join("missing").to_s)

    expect { cli.analyze(images: [], text: "x") }.to raise_error(PlantAnalyzer::Error, "claude is not installed")
  end
end
