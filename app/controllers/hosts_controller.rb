class HostsController < ApplicationController
  def index
      render json: Host.all
  end

  def create
      host = Host.create!(host_params)
      render json: { id: host.id, token: host.token }, status: :created
  end

    private

    def host_params
      params.require(:host).permit(:name)
    end
end
