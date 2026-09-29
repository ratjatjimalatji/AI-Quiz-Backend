module PowerUps
  class GlitchSabotageService
    GLITCH_DURATION_MS = 10_000

    def self.call(initiator:, question:, victim_id:)
      new(initiator: initiator, question: question, victim_id: victim_id).call
    end

    def initialize(initiator:, question:, victim_id:)
      @initiator = initiator
      @question = question
      @victim_id = victim_id
      @game = initiator.game
    end

    def call
      victim = @game.players.where(eliminated: false).find_by(id: @victim_id)
      validate!(victim)

      ActiveRecord::Base.transaction do
        @initiator.power_ups = @initiator.power_ups - [ "glitch_sabotage" ]
        @initiator.save!
      end

      broadcast_sabotage_event!(victim)

      {
        success: true,
        data: {
        question_id: @question.id,
        victim_player_id: victim.id,
        glitch_duration_ms: GLITCH_DURATION_MS
        }
      }
    rescue StandardError => e
      { success: false, error: e.message }
    end

    private

    def validate!(victim)
      raise "Power-up not available" unless @initiator.power_ups.include?("glitch_sabotage")
      raise "Game is not accepting submissions" unless @game.status == "in_progress"
      raise "Target player not found or eliminated" if victim.nil?
      raise "Cannot sabotage yourself" if @initiator.id == victim.id
    end

    def broadcast_sabotage_event!(victim)
      ActionCable.server.broadcast(
        "game_room_#{@game.game_code}",
        {
          event: "glitch_attack",
          initiator_id: @initiator.id,
          initiator_name: @initiator.username,
          victim_id: victim.id,
          victim_name: victim.username,
          question_id: @question.id,
          glitch_duration_ms: GLITCH_DURATION_MS
        }
      )
    end
  end
end
