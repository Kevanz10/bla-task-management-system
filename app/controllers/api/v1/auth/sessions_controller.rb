module Api
  module V1
    module Auth
      class SessionsController < ApplicationController
        def create
          user = User.find_by(email: session_params[:email])

          if user&.authenticate(session_params[:password])
            token = JwtToken.encode(user.id)
            render json: {
              user: {
                id: user.id,
                email: user.email
              },
              token: token
            }, status: :ok
          else
            render json: {
              errors: [ {
                status: "401",
                title: "Unauthorized",
                detail: "Invalid email or password"
              } ]
            }, status: :unauthorized
          end
        end

        private

        def session_params
          params.require(:user).permit(:email, :password)
        end
      end
    end
  end
end
