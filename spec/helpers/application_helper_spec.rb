require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#names_sentence" do
    it "lists up to three names, then the first two and how many others" do
      expect(helper.names_sentence(%w[Basilic])).to eq("Basilic")
      expect(helper.names_sentence(%w[Basilic Citronnier])).to eq("Basilic et Citronnier")
      expect(helper.names_sentence(%w[Basilic Citronnier Menthe])).to eq("Basilic, Citronnier et Menthe")
      expect(helper.names_sentence(%w[Basilic Citronnier Menthe Thym])).to eq("Basilic, Citronnier et 2 autres")
      expect(helper.names_sentence(%w[A B C D E])).to eq("A, B et 3 autres")
    end
  end
end
