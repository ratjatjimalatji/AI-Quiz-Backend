class ApplicationController < ActionController::API
    attr_reader :current_host

    def authenticate_host!
        token = extract_token
        @current_host = Player.hosts.find_by(token: token) if token.present?

        unless @current_host
            render json: { error: "Unauthorized"}, status: :unauthorized
        end
    end

    private

    def extract_token
        header = request.headers[Networking::Headers::AUTHORIZATION]
        if header.present? && header.start_with?(Networking::Authentication::BEARER)
            header.split(" ").last
        else
            request.headers["X-Host-Token"] || params[:token]
        end
    end

    def authorize_game_host!(game)
        unless @current_host && game.players.exists?(id: @current_host.id, is_host: true)
        render json: { error: "Forbidden: You are not the game host" }, status: :forbidden
        end
    end
end
