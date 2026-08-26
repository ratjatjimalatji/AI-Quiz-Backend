module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_host

    def connect
      self.current_host = find_verified_host
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
  end
end
