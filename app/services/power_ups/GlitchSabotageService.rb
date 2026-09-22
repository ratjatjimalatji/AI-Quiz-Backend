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
      target_player = @game.players.where(eliminated: false).find_by(id: @victim_id)
      current_player = @game.players.find_by(id: @initiator.id)
      validate!(target_player)

      ActiveRecord::Base.transaction do
        # Deduct the power up from the inventory
        @initiator.power_ups = @initiator.power_ups - [ "glitch_sabotage" ]
        @initiator.save!
      end

      broadcast_sabotage_event!

      { success: true, target_player: target_player, current_player: current_player, glitch_duration_ms: GLITCH_DURATION_MS }
    rescue StandardError => e
      { success: false, error: e.message }
    end

    private

    def validate!
      raise "Power-up not available" unless @initiator.power_ups.include?("glitch_sabotage")
      raise "Game is not accepting submissions" unless @game.status == "in_progress"
      raise "Target player not found or eliminated" unless @game.players.where(elimated: false).exists?(id: @victim_id)
      raise "Cannot sabotage yourself" if @initiator.id == @victim_id
    end

    def broadcast_sabotage_event!
      ActionCable.server.broadcast(
        "game_room_#{@game.game_code}",
        {
          event: "#{@initiator.username} used glitch sabotaged on #{@victim.username}",
          initiator_id: @initiator.id,
          initiator_name: @initiator.username,
          victim_id: @victim.id,
          victim_name: @victim.username,
          question_id: @question.id
        }
      )
    end
  end
end
