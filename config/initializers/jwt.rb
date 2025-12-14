# JWT Configuration
# Reads JWT secret from credentials or environment variable
JWT_SECRET = ENV.fetch("JWT_SECRET") do
  Rails.application.credentials.dig(:jwt_secret) || SecureRandom.hex(64)
end
