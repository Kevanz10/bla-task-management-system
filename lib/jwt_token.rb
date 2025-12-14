class JwtToken
  ALGORITHM = "HS256"
  EXPIRATION = 24

  class << self
    def encode(user_id)
      payload = {
        user_id: user_id,
        exp: Time.now.to_i + (EXPIRATION * 3600),
        iat: Time.now.to_i
      }

      JWT.encode(payload, secret, ALGORITHM)
    end

    def decode(token)
      decoded = JWT.decode(token, secret, true, { algorithm: ALGORITHM })
      decoded.first["user_id"]
    rescue JWT::DecodeError, JWT::ExpiredSignature, JWT::VerificationError => e
      raise e
    end

    private

    def secret
      JWT_SECRET
    end
  end
end
