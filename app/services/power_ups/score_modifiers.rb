# app/services/power_ups/score_modifiers.rb
module PowerUps
  module ScoreModifiers
    class Standard
      def self.apply(score, correct:)
        correct ? score : 0
      end
    end

    class DoublePoints
      def self.apply(score, correct:)
        correct ? score * 2 : 0
      end
    end

    REGISTRY = {
      "double_points" => DoublePoints
    }.freeze

    def self.for(power_up_name)
      REGISTRY.fetch(power_up_name.to_s, Standard)
    end
  end
end
