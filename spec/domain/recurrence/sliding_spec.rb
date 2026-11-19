require "rails_helper"

RSpec.describe Recurrence::Sliding do
  let(:zone) { ActiveSupport::TimeZone["Indian/Reunion"] }

  def next_due(interval_days, last_completed_at)
    described_class.new(interval_days:).next_due_at(last_completed_at:)
  end

  describe "#next_due_at" do
    it "tombe interval_days jours après la réalisation, au début de la journée" do
      expect(next_due(3, zone.parse("2026-11-16 18:42"))).to eq(zone.parse("2026-11-19 00:00"))
    end

    it "garde le fuseau de la réalisation (Indian/Reunion, UTC+4)" do
      due = next_due(1, zone.parse("2026-11-16 02:00"))

      expect(due.time_zone).to eq(zone)
      expect(due.utc).to eq(Time.utc(2026, 11, 16, 20, 0))
    end

    it "compte le jour local, même quand la réalisation est la veille en UTC" do
      # 2026-11-17 01:00 à La Réunion = 2026-11-16 21:00 UTC
      expect(next_due(2, zone.parse("2026-11-17 01:00"))).to eq(zone.parse("2026-11-19 00:00"))
    end

    it "franchit une fin de mois et une fin d'année" do
      expect(next_due(3, zone.parse("2026-11-29 08:00"))).to eq(zone.parse("2026-12-02 00:00"))
      expect(next_due(5, zone.parse("2026-12-30 08:00"))).to eq(zone.parse("2027-01-04 00:00"))
    end

    it "compte le 29 février d'une année bissextile, pas celui d'une année ordinaire" do
      expect(next_due(1, zone.parse("2028-02-28 08:00"))).to eq(zone.parse("2028-02-29 00:00"))
      expect(next_due(1, zone.parse("2027-02-28 08:00"))).to eq(zone.parse("2027-03-01 00:00"))
    end

    it "accepte les bornes 1 et 60 jours" do
      expect(next_due(1, zone.parse("2026-11-16 23:59"))).to eq(zone.parse("2026-11-17 00:00"))
      expect(next_due(60, zone.parse("2026-11-16 00:00"))).to eq(zone.parse("2027-01-15 00:00"))
    end

    it "reste à minuit local lors d'un changement d'heure (fuseau avec heure d'été)" do
      paris = ActiveSupport::TimeZone["Europe/Paris"]

      expect(next_due(2, paris.parse("2026-03-28 10:00"))).to eq(paris.parse("2026-03-30 00:00"))
    end
  end

  describe "intervalle invalide" do
    [ 0, 61, -1, nil, "3", 2.5 ].each do |value|
      it "refuse #{value.inspect}" do
        expect { described_class.new(interval_days: value) }.to raise_error(Recurrence::InvalidConfig)
      end
    end
  end
end
