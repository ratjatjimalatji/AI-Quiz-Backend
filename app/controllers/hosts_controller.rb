class HostsController < ApplicationController
  def create
      host = Host.create!(name: params[:name])
      render json: { id: host.id, token: host.token }, status: :created
  end
end
