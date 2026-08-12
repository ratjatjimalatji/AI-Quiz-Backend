class HostsController < ApplicationController
    def register
        host = Player.new(host_params.merge(is_host: true))

        if host.save
            render json: 
            {
                host: host_response(host),
                token: host.token
            }, status: :created
        else
            render json: { errors: host.errors.full_messages}, status:
             :unprocessable_entity
        end
    end

    private

    def host_params
        params.permit(:username, :email, :password, :password_confirmation)
    end

    def host_response(host)
        {
            id: host.id,
            username: host.username
            email: host.email,
            is_host: host.is_host
        }
    end

    def login 
        login_key = params[:email] || params[:username] || [:login]
        host = Player.hosts.find_by(
            "LOWER(email) =? OR LOWER(username) = ?",
            login_key.to_s.downcase,
            login_key.to_s.downcase
            )

        if host&.authenticate(params[:password])
            host.regenerate_token if host.token.nil?
            render json: {
                host: host_response(host),
                token: host.token
            }, status: :ok
        else
            render json: { error: "Invalid login credentials"}
            , status: :unauthorized
        end
    end
end
