class ApplicationController < ActionController::API
    def current_host
     unless @current_host ||= Host.find_by(token: extract_token) if extract_token.present?
       render json: { error: I18n.t("networking.errors.missing_token") }, status: :unauthorized
     end
    end

    def authenticate_host!
        return if @current_host

        render json: { error: I18n.t("networking.errors.unauthorized") }, status: :unauthorized
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
        render json: { error: I18n.t("networking.errors.forbidden")}, status: :forbidden
        end
    end
end
