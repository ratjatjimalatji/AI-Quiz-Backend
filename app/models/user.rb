class User < ApplicationRecord
    has_many :hosted_games,
           class_name: "Game",
           foreign_key: :host_id
end
