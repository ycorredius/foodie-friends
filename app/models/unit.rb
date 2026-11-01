# Units a recipe ingredient can be measured in, and conversion between the
# metric and US customary systems.
#
# Mass converts through grams and volume through millilitres. Count units
# ("clove", "can", "pinch") belong to no system and are never converted.
module Unit
  Definition = Data.define(:key, :dimension, :system, :to_base)
  Amount = Data.define(:quantity, :unit)

  SYSTEMS = %w[us_customary metric].freeze

  DEFINITIONS = [
    Definition.new("g", :mass, "metric", 1),
    Definition.new("kg", :mass, "metric", 1000),
    Definition.new("oz", :mass, "us_customary", BigDecimal("28.349523125")),
    Definition.new("lb", :mass, "us_customary", BigDecimal("453.59237")),
    Definition.new("ml", :volume, "metric", 1),
    Definition.new("l", :volume, "metric", 1000),
    Definition.new("tsp", :volume, "us_customary", BigDecimal("4.92892159375")),
    Definition.new("tbsp", :volume, "us_customary", BigDecimal("14.78676478125")),
    Definition.new("fl_oz", :volume, "us_customary", BigDecimal("29.5735295625")),
    Definition.new("cup", :volume, "us_customary", BigDecimal("236.5882365")),
    Definition.new("pint", :volume, "us_customary", BigDecimal("473.176473")),
    Definition.new("quart", :volume, "us_customary", BigDecimal("946.352946")),
    Definition.new("gallon", :volume, "us_customary", BigDecimal("3785.411784")),
    *%w[each clove slice can package bunch sprig stick pinch dash].map { |key| Definition.new(key, :count, nil, nil) }
  ].index_by(&:key).freeze

  # For each system and dimension, the units to display, largest first, with the
  # smallest quantity (in base units) each is used for.
  DISPLAY_UNITS = {
    "metric" => {
      mass: [["kg", 1000], ["g", 0]],
      volume: [["l", 1000], ["ml", 0]]
    },
    "us_customary" => {
      mass: [["lb", BigDecimal("453.59237")], ["oz", 0]],
      volume: [["cup", BigDecimal("59.147059125")], ["tbsp", BigDecimal("14.78676478125")], ["tsp", 0]]
    }
  }.freeze

  def self.keys
    DEFINITIONS.keys
  end

  def self.[](key)
    DEFINITIONS.fetch(key)
  end

  # Returns quantity * factor expressed in the given system. Amounts already in
  # that system keep the author's unit; count units and missing quantities pass
  # through unchanged.
  def self.convert(quantity, unit, system:, factor: 1)
    return Amount.new(quantity, unit) if quantity.nil?

    quantity *= factor
    definition = DEFINITIONS[unit]
    return Amount.new(round(quantity, unit), unit) if definition.nil? || definition.system.nil? || definition.system == system

    base = quantity * definition.to_base
    display_unit, = DISPLAY_UNITS.fetch(system).fetch(definition.dimension).find { |_key, min| base >= min }
    Amount.new(round(base / self[display_unit].to_base, display_unit), display_unit)
  end

  def self.round(quantity, unit)
    if %w[g ml].include?(unit) && quantity >= 10
      quantity.round
    elsif %w[g ml].include?(unit)
      quantity.round(1)
    else
      quantity.round(2)
    end
  end
  private_class_method :round
end
