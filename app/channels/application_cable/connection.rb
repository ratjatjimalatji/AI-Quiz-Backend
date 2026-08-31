module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_host, :current_player

    def connect
      self.current_host = find_verified_host
      self.current_player = find_verified_player
    end

    private

    def find_verified_host
      token = request.params[:token] || request.headers[Networking::Headers::TOKEN]
      if (verified_host = Host.find_by(token: token))
          verified_host
      else
          reject_unauthorized_connection
      end
    end

    def find_verified_player
      token = request.params[:token] || request.headers[Networking::Headers::TOKEN]
      if (verified_player = Player.find_by(token: token))
          verified_player
      else
          reject_unauthorized_connection
      end
    end
  end
end
