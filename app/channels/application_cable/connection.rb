module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_host, :current_player

    def connect
      authenticate_connection
    end

    private

    def authenticate_connection
      token = request.params[:token].presence ||
              request.headers[Networking::Headers::TOKEN].presence

      return reject_unauthorized_connection if token.blank?

      if (host = Host.find_by(token: token))
        self.current_host = host
      elsif (player = Player.find_by(token: token))
        self.current_player = player
      else
        reject_unauthorized_connection
      end
    end
  end
end
