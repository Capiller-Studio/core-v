# frozen_string_literal: true

# == Schema Information
#
# Table name: channel_apis
#
#  id                     :uuid             not null, primary key
#  configurations         :jsonb            not null
#  data                   :jsonb            not null
#  name                   :string
#  status                 :integer          default("active"), not null
#  webhook_configurations :jsonb            not null
#  webhook_password       :string
#  webhook_secret         :string           not null
#  webhook_url            :string
#  webhook_username       :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  account_id             :uuid             not null
#
# Indexes
#
#  index_channel_apis_on_account_id                 (account_id)
#  index_channel_apis_on_account_id_and_created_at  (account_id,created_at)
#  index_channel_apis_on_account_id_and_name        (account_id,name)
#  index_channel_apis_on_status                     (status)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id) ON DELETE => cascade
#
module Channel
  class Api < ShardRecord
    include Channelable
    include Routable
    
    belongs_to :account

    has_many :inboxes, as: :channel, dependent: :destroy
    has_one :primary_inbox, -> { where(primary_inbox: true) }, as: :channel, class_name: "Inbox"
    accepts_nested_attributes_for :primary_inbox, update_only: true

    has_many :webhook_deliveries, as: :resource, dependent: :destroy

    encrypts :webhook_secret
    encrypts :hmac_token

    validates :identifier, presence: true, uniqueness: { scope: :account_id, message: "is already in use" }

    enum :status, { active: 0, disconnected: 1 }

    before_validation :generate_identifier, on: :create
    before_validation :generate_webhook_secret, on: :create
    before_validation :generate_hmac_token, on: :create

    # --- Routable overrides ---

    def routing_identifier
      identifier
    end

    def routing_type
      "api"
    end

    # --- Webhooks ---

    # Public endpoint where the customer sends their payloads to us.
    def webhook_endpoint
      host = Rails.application.credentials.dig(Rails.env.to_sym, :host) || Rails.application.credentials.dig(:host)
      "#{host}/webhooks/api/#{account_id}/#{id}"
    end

    private

    def generate_identifier
      self.identifier = name.parameterize if identifier.blank? && name.present?
      
      # Ensure uniqueness by appending a random hex if conflict exists
      if identifier.present?
        while Channel::Api.exists?(account_id: account_id, identifier: identifier)
          self.identifier = "#{name.parameterize}-#{SecureRandom.hex(4)}"
        end
      end
    end

    def generate_webhook_secret
      self.webhook_secret ||= SecureRandom.hex(24)
    end

    def generate_hmac_token
      self.hmac_token ||= SecureRandom.hex(32)
    end
  end
end
