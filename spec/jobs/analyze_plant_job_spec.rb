require "rails_helper"

RSpec.describe AnalyzePlantJob do
  let(:analysis) { create(:plant_analysis) }

  it "runs the analysis" do
    described_class.perform_now(analysis)

    expect(analysis.reload).to be_done
  end

  it "marks the analysis failed on an unexpected error, without retrying" do
    allow(Plants::Analyze).to receive(:new).and_raise(ArgumentError, "boom")

    expect { described_class.perform_now(analysis) }.to raise_error(ArgumentError)
    expect(analysis.reload).to have_attributes(status: "failed", error: "unexpected: ArgumentError")
  end
end
