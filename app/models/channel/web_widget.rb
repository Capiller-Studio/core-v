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
    include Channelable
    include Routable
    include FlagShihTzu
    include Translateable
    include Trackable

    TRANSLATABLE_FIELDS = %i[launcher_text reply_time_text pre_chat_title pre_chat_subtitle welcome_title welcome_tagline].freeze

    belongs_to :account
    belongs_to :portal, class_name: "HelpCenter::Portal", optional: true
    belongs_to :pre_chat_form, class_name: "Channel::ContactForm", optional: true
    belongs_to :fallback_channel, polymorphic: true, optional: true

    has_one_attached :logo
    validates :logo, content_type: ['image/png', 'image/jpeg', 'image/svg+xml', 'image/webp'],
                     size: { less_than: 2.megabytes }

    has_one_attached :launcher_icon
    validates :launcher_icon, content_type: ['image/png', 'image/jpeg', 'image/svg+xml', 'image/webp'],
                              size: { less_than: 2.megabytes }

    has_many :inboxes, as: :channel, dependent: :destroy
    has_one :primary_inbox, -> { where(primary_inbox: true) }, as: :channel, class_name: "Inbox"
    accepts_nested_attributes_for :primary_inbox, update_only: true

    def scaled_logo
      return nil unless logo.attached?
      logo.content_type&.include?('svg') ? logo : logo.variant(resize_to_limit: [500, 500])
    end

    def scaled_launcher_icon
      return nil unless launcher_icon.attached?
      launcher_icon.content_type&.include?('svg') ? launcher_icon : launcher_icon.variant(resize_to_limit: [200, 200])
    end

    translates(*TRANSLATABLE_FIELDS)

    has_flags 1 => :anonymous_allowed,
              2 => :help_center_enabled,
              3 => :pre_chat_form_enabled,
              4 => :secure_identity_enforced,
              5 => :custom_branding,
              column: "flags"

    enum :status, { active: 0 }

    store_accessor :ui_configurations, :theme_color, :position, :footer_text

    def fallback_locale
      default_locale.presence || super
    end

    before_validation :ensure_secret, on: :create
    validates :secret, presence: true, uniqueness: true
    validate :validate_allowed_hosts

    def supported_formatting
      [:bold, :italic, :strikethrough, :code, :ul, :ol, :link, :image, :file]
    end

    def hmac_token
      secret
    end

    def allowed_hosts=(value)
      if value.is_a?(String)
        super(value.split(",").map(&:strip).compact_blank)
      elsif value.is_a?(Array)
        if value.length == 1 && value.first.is_a?(String) && value.first.include?(",")
          super(value.first.split(",").map(&:strip).compact_blank)
        else
          super(value.compact_blank.map(&:strip).compact_blank)
        end
      else
        super
      end
    end

    private

    def validate_allowed_hosts
      unless allowed_hosts.is_a?(Array)
        errors.add(:allowed_hosts, "must be an array")
        return
      end

      allowed_hosts.each do |host|
        unless host.match?(URI::DEFAULT_PARSER.make_regexp(%w[http https]))
          errors.add(:allowed_hosts, "contains invalid URL: #{host}")
        end
      end
    end

    def ensure_secret
      self.secret ||= SecureRandom.hex(24)
    end
  end
end
