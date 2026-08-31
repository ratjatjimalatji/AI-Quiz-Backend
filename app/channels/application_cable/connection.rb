module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_host, :current_player

    def connect
      authenticate_connection
    end

    private

    def authenticate_connection
      if (host = find_host)
        self.current_host = host
      elsif (player = find_player)
        self.current_player = player
      else
        reject_unauthorized_connection
      end
    end

    def find_host
      token = request.params[:token] ||
              request.headers[Networking::Headers::TOKEN]

      Host.find_by(token: token)
    end

    def find_player
      token = request.params[:token] ||
              request.headers[Networking::Headers::TOKEN]

      Player.find_by(token: token)
    end
  end
end
