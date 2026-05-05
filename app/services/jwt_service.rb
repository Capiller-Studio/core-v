# frozen_string_literal: true

class JwtService
  ALGORITHM = "HS256"
  DEFAULT_EXPIRY = 24.hours

  class << self
    def encode(payload, expiry: DEFAULT_EXPIRY)
      payload = payload.merge(
        exp: expiry.from_now.to_i,
        iat: Time.current.to_i
      )
      JWT.encode(payload, secret_key, ALGORITHM)
    end

    def decode(token)
      decoded = JWT.decode(token, secret_key, true, { algorithm: ALGORITHM })
      decoded.first.with_indifferent_access
    rescue JWT::ExpiredSignature, JWT::DecodeError
      nil
    end

    private

    def secret_key
      Rails.application.credentials.secret_key_base
    end
  end
end
