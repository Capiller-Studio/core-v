# frozen_string_literal: true

# == Schema Information
#
# Table name: channel_web_widgets
#
#  id                :uuid             not null, primary key
#  configurations    :jsonb            not null
#  data              :jsonb            not null
#  flags             :integer          default(0), not null
#  name              :string
#  secret            :string           not null
#  status            :integer          default("active"), not null
#  ui_configurations :jsonb            not null
#  website_url       :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :uuid             not null
#  portal_id         :uuid
#
# Indexes
#
#  index_channel_web_widgets_on_account_id                 (account_id)
#  index_channel_web_widgets_on_account_id_and_created_at  (account_id,created_at)
#  index_channel_web_widgets_on_account_id_and_name        (account_id,name)
#  index_channel_web_widgets_on_portal_id                  (portal_id)
#  index_channel_web_widgets_on_status                     (status)
#  index_channel_web_widgets_on_website_url                (website_url)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id) ON DELETE => cascade
#
module Channel
  class WebWidget < ShardRecord
    include Routable
    include FlagShihTzu

    belongs_to :account
    belongs_to :portal, class_name: "HelpCenter::Portal", optional: true

    has_many :inboxes, as: :channel, dependent: :destroy

    has_flags 1 => :anonymous_allowed,
              2 => :help_center_enabled,
              3 => :pre_chat_form_enabled,
              column: "flags"

    enum :status, { active: 0 }

    store_accessor :ui_configurations, :theme_color, :welcome_title, :welcome_tagline, :position

    before_validation :ensure_secret, on: :create
    validates :secret, presence: true, uniqueness: true

    def hmac_token
      secret
    end

    private

    def ensure_secret
      self.secret ||= SecureRandom.hex(24)
    end
  end
end
