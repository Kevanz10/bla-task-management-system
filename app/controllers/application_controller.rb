class ApplicationController < ActionController::API
  include JwtAuthenticatable

  rescue_from JWT::DecodeError, with: :handle_authentication_error
  rescue_from JWT::ExpiredSignature, with: :handle_authentication_error
  rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :handle_validation_error

  private

  def handle_authentication_error(exception)
    render json: {
      errors: [ {
        status: "401",
        title: "Unauthorized",
        detail: "Invalid or missing authentication token"
      } ]
    }, status: :unauthorized
  end

  def handle_not_found(exception)
    render json: {
      errors: [ {
        status: "404",
        title: "Not Found",
        detail: exception.message
      } ]
    }, status: :not_found
  end

  def handle_validation_error(exception)
    render json: {
      errors: exception.record.errors.full_messages.map do |message|
        {
          status: "422",
          title: "Invalid params",
          detail: message
        }
      end
    }, status: :unprocessable_content
  end
end
