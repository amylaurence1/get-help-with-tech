module SignInWithToken
  extend ActiveSupport::Concern

  included do
    validates :sign_in_token, uniqueness: true, allow_nil: true

    def generate_token!(ttl: nil)
      ttl ||= (ENV['SIGN_IN_TOKEN_TTL_SECONDS'] || 1800)

      update!(
        sign_in_token: SecureRandom.uuid,
        sign_in_token_expires_at: Time.now.utc + ttl.seconds,
      )
      sign_in_token
    end

    def token_is_valid?(token:, identifier:)
      [
        token == sign_in_token,
        (sign_in_token_expires_at.present? && sign_in_token_expires_at >= Time.now.utc),
        identifier == sign_in_identifier(token),
      ].all?
    end

    def clear_token!
      update!(sign_in_token: nil, sign_in_token_expires_at: nil)
    end

    def sign_in_identifier(token)
      Digest::SHA256.hexdigest [email_address, token].join('-')
    end
  end
end
