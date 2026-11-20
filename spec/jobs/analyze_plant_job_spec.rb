require "rails_helper"

RSpec.describe AnalyzePlantJob do
  let(:analysis) { create(:plant_analysis) }

  it "runs the analysis" do
    described_class.perform_now(analysis)

    expect(analysis.reload).to be_done
  end

  it "marks the analysis failed on an unexpected error and refreshes the page, without retrying" do
    allow(Plants::Analyze).to receive(:new).and_raise(ArgumentError, "boom")

    expect { described_class.perform_now(analysis) }
      .to raise_error(ArgumentError)
      .and have_broadcasted_to(analysis.plant.to_gid_param).from_channel(Turbo::StreamsChannel)
    expect(analysis.reload).to have_attributes(status: "failed", error: "unexpected: ArgumentError")
  end

  it "keeps the result of an analysis that finished before the error" do
    allow(Plants::Analyze).to receive(:new).and_wrap_original do |original|
      analysis.update!(status: :done, health: :ok, observations: "OK")
      raise ArgumentError, "after the answer"
    end

    expect { described_class.perform_now(analysis) }.to raise_error(ArgumentError)
    expect(analysis.reload).to have_attributes(status: "done", error: nil)
  end
end
