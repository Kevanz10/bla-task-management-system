module JwtAuthenticatable
  extend ActiveSupport::Concern

  included do
    attr_reader :current_user
  end

  def authenticate_user!
    token = extract_token_from_header
    raise JWT::DecodeError, "Missing token" if token.blank?

    user_id = JwtToken.decode(token)
    @current_user = User.find(user_id)
  rescue JWT::DecodeError, JWT::ExpiredSignature, ActiveRecord::RecordNotFound => e
    raise JWT::DecodeError, "Invalid or expired token"
  end

  private

  def extract_token_from_header
    auth_header = request.headers["Authorization"]
    return nil unless auth_header

    auth_header.split(" ").last if auth_header.start_with?("Bearer ")
  end
end
