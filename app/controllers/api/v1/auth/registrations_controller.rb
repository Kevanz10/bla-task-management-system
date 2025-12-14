module Api
  module V1
    module Auth
      class RegistrationsController < ApplicationController
        def create
          user = User.new(registration_params)
          user.save!
          token = JwtToken.encode(user.id)

          render json: {
            user: {
              id: user.id,
              email: user.email,
              created_at: user.created_at
            },
            token: token
          }, status: :created
        end

        private

        def registration_params
          params.require(:user).permit(:email, :password)
        end
      end
    end
  end
end
