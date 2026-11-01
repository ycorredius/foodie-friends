require "rails_helper"

RSpec.describe Unit do
  def convert(quantity, unit, system:, factor: 1)
    amount = Unit.convert(quantity.nil? ? nil : BigDecimal(quantity.to_s), unit, system: system, factor: factor)
    [amount.quantity&.to_f, amount.unit]
  end

  describe ".convert" do
    it "keeps amounts already in the reader's system" do
      expect(convert(2, "cup", system: "us_customary")).to eq([2.0, "cup"])
      expect(convert(1500, "g", system: "metric")).to eq([1500.0, "g"])
    end

    it "converts US volume to metric" do
      expect(convert(1, "cup", system: "metric")).to eq([237.0, "ml"])
      expect(convert(5, "cup", system: "metric")).to eq([1.18, "l"])
      expect(convert(1, "tsp", system: "metric")).to eq([4.9, "ml"])
    end

    it "converts metric volume to US, picking a cooking-friendly unit" do
      expect(convert(250, "ml", system: "us_customary")).to eq([1.06, "cup"])
      expect(convert(30, "ml", system: "us_customary")).to eq([2.03, "tbsp"])
      expect(convert(5, "ml", system: "us_customary")).to eq([1.01, "tsp"])
    end

    it "converts mass both ways" do
      expect(convert(1, "lb", system: "metric")).to eq([454.0, "g"])
      expect(convert(3, "lb", system: "metric")).to eq([1.36, "kg"])
      expect(convert(100, "g", system: "us_customary")).to eq([3.53, "oz"])
      expect(convert(1, "kg", system: "us_customary")).to eq([2.2, "lb"])
    end

    it "scales by the factor before converting" do
      expect(convert(1, "cup", system: "us_customary", factor: 2)).to eq([2.0, "cup"])
      expect(convert(0.5, "lb", system: "metric", factor: 3)).to eq([680.0, "g"])
    end

    it "scales count units without converting them" do
      expect(convert(2, "clove", system: "metric", factor: BigDecimal("1.5"))).to eq([3.0, "clove"])
    end

    it "passes through lines without a quantity" do
      expect(convert(nil, nil, system: "metric", factor: 2)).to eq([nil, nil])
    end

    it "scales unitless quantities" do
      expect(convert(3, nil, system: "metric", factor: 2)).to eq([6.0, nil])
    end
  end
end
