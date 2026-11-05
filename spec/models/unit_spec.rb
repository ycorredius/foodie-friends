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

  describe ".sum" do
    def sum(*amounts, system:)
      Unit.sum(amounts.map { |q, u| Unit::Amount.new(q && BigDecimal(q.to_s), u) })
        .map { |amount| Unit.display(amount, system: system) }
        .map { |amount| [amount.quantity.to_f, amount.unit] }
    end

    it "adds volumes across systems and shows the total in the reader's system" do
      expect(sum([1, "cup"], [4, "tbsp"], system: "us_customary")).to eq([[1.25, "cup"]])
      expect(sum([1, "cup"], [200, "ml"], system: "metric")).to eq([[437.0, "ml"]])
    end

    it "adds masses and picks a unit for the total's size" do
      expect(sum([200, "g"], [1, "lb"], system: "us_customary")).to eq([[1.44, "lb"]])
      expect(sum([600, "g"], [0.5, "kg"], system: "metric")).to eq([[1.1, "kg"]])
    end

    it "keeps mass and volume separate" do
      expect(sum([2, "cup"], [100, "g"], [1, "cup"], system: "us_customary")).to eq([[3.0, "cup"], [3.53, "oz"]])
    end

    it "adds count units and unitless quantities per unit, without converting" do
      expect(sum([2, "clove"], [1, "can"], [1.5, "clove"], [2, nil], [1, nil], system: "metric"))
        .to eq([[3.5, "clove"], [1.0, "can"], [3.0, nil]])
    end

    it "totals in grams and millilitres, unrounded" do
      expect(Unit.sum([Unit::Amount.new(1, "cup"), Unit::Amount.new(1, "lb")]))
        .to eq([Unit::Amount.new(BigDecimal("236.5882365"), "ml"), Unit::Amount.new(BigDecimal("453.59237"), "g")])
    end

    it "leaves out amounts without a quantity" do
      expect(sum([nil, nil], [1, "tsp"], system: "us_customary")).to eq([[1.0, "tsp"]])
      expect(sum([nil, nil], system: "us_customary")).to eq([])
    end
  end
end
