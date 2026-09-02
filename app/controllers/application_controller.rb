class ApplicationController < ActionController::API
    def current_host
     @current_host ||= Host.find_by(token: extract_token)
    end

    def authenticate_host!
        return if current_host
         puts "CURRENT HOST: #{current_host.inspect}"
        render json: { error: I18n.t("networking.errors.unauthorized") }, status: :unauthorized
    end

    private

    def extract_token
        header = request.headers[Networking::Headers::AUTHORIZATION]
        puts "AUTH HEADER: #{header.inspect}"
        if header.present? && header.start_with?(Networking::Authentication::BEARER)
            header.split(" ").last
        end
    end

    def authorize_game_host!(game)
        unless @current_host && (game.host.id == @current_host.id)
        render json: { error: I18n.t("networking.errors.forbidden") }, status: :forbidden
        end
    end
end
