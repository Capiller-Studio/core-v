# frozen_string_literal: true

# == Schema Information
#
# Table name: domains
#
#  id              :uuid             not null, primary key
#  cname_target    :string           default("")
#  dns_status      :integer          default("dns_unverified"), not null
#  dns_verified_at :datetime
#  domain_type     :integer          default("subdomain"), not null
#  last_checked_at :datetime
#  name            :string           default("")
#  ssl_added_at    :datetime
#  ssl_expires_at  :datetime
#  ssl_status      :integer          default("ssl_none"), not null
#  status          :integer          default("active"), not null
#  value           :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :uuid             not null
#
# Indexes
#
#  index_domains_on_account_id                  (account_id)
#  index_domains_on_account_id_and_created_at   (account_id,created_at)
#  index_domains_on_account_id_and_domain_type  (account_id,domain_type)
#  index_domains_on_dns_status                  (dns_status)
#  index_domains_on_domain_type                 (domain_type)
#  index_domains_on_ssl_status                  (ssl_status)
#  index_domains_on_status                      (status)
#  index_domains_on_value                       (value) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id) ON DELETE => cascade
#
class Domain < ApplicationRecord
  require "resolv"

  belongs_to :account
  has_one :portal, class_name: "HelpCenter::Portal", dependent: :nullify

  # --- Enums ---
  enum :status,      { active: 0, inactive: 1, suspended: 2 }
  enum :domain_type, { subdomain: 0, custom: 1 }
  enum :dns_status,  { dns_unverified: 0, dns_pending: 1, dns_verified: 2, dns_failed: 3 }
  enum :ssl_status,  { ssl_none: 0, ssl_pending: 1, ssl_active: 2, ssl_expired: 3, ssl_failed: 4 }

  # --- Validations ---
  validates :value, presence: true,
                    uniqueness: { case_sensitive: false, message: "is already taken" }
  validates :value, format: {
    with: /\A[a-z0-9]([a-z0-9\-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9\-]*[a-z0-9])?)*\z/i,
    message: "contains invalid characters"
  }, allow_blank: true
  validates :domain_type, presence: true

  validate :value_not_reserved,                 if: :subdomain?
  validate :value_is_valid_subdomain_format,    if: :subdomain?
  validate :value_is_valid_custom_domain_format, if: :custom?
  validate :account_custom_domain_limit,        on: :create, if: :custom?

  # --- Scopes ---
  scope :subdomains,          -> { where(domain_type: :subdomain) }
  scope :custom_domains,      -> { where(domain_type: :custom) }
  scope :dns_verified_only,   -> { where(dns_status: :dns_verified) }
  scope :ssl_active_only,     -> { where(ssl_status: :ssl_active) }
  scope :needing_dns_check,   -> { custom_domains.where(dns_status: [:dns_unverified, :dns_pending]) }
  scope :needing_ssl_renewal, -> { where(ssl_status: :ssl_active).where("ssl_expires_at < ?", 30.days.from_now) }
  scope :unattached,          -> { left_joins(:portal).where(help_center_portals: { id: nil }) }

  # --- Callbacks ---
  before_validation :normalize_value
  before_validation :set_subdomain_defaults, if: :subdomain?
  before_validation :set_custom_domain_defaults, if: :custom?

  # --- Constants ---
  SUBDOMAIN_SUFFIX   = ".helpbolic.com"
  CNAME_TARGET       = "custom.helpbolic.com"
  MIN_SUBDOMAIN_LENGTH = 3
  MAX_SUBDOMAIN_LENGTH = 63

  # Reserved subdomains that cannot be used by tenants.
  # Includes infrastructure names, system paths, brand names, and abusive terms.
  RESERVED_SUBDOMAINS = %w[
    www mail smtp imap pop pop3 ftp ssh sftp api app admin console support help
    status blog docs wiki careers jobs billing payments invoice checkout pay
    security abuse postmaster webmaster hostmaster info contact us team
    noreply no-reply newsletter marketing sales demo test testing staging
    dev development preview sandbox cdn assets static media images img
    download downloads upload uploads file files backup backups
    login signin signup register auth oauth oauth2 sso saml
    dashboard panel cpanel control manage manager management
    root system internal private public enterprise pro premium
    fraud phishing spam scam hack hacker exploit malware virus
    deskbolic helpbolic techbolic
    account accounts user users profile settings config
    portal portals helpcenter helpcenters kb knowledgebase
    search sitemap robots feed rss atom
    mobile desktop tablet android ios
    store shop marketplace
    community forum discuss
    legal privacy terms tos gdpr compliance
    notification notifications alert alerts webhook webhooks
    calendar schedule meeting meetings
    report reports analytics metrics
    survey surveys feedback reviews
    event events webinar webinars
    ticket tickets issue issues bug bugs
    chat messenger live livechat
    video audio call calls conference
  ].freeze

  # --- Public Methods ---

  # Returns just the slug portion of a subdomain (without the suffix)
  def subdomain_slug
    return nil unless subdomain?
    value&.chomp(SUBDOMAIN_SUFFIX)
  end

  # Whether this domain is ready to serve traffic
  def operational?
    active? && (subdomain? || (dns_verified? && (ssl_active? || ssl_pending?)))
  end

  # Human-readable display of DNS instructions for custom domains
  def dns_instructions
    return nil unless custom?
    {
      record_type: I18n.t("domains.dns_instructions.record_type"),
      host: value,
      target: CNAME_TARGET,
      description: I18n.t("domains.dns_instructions.description", domain: value, target: CNAME_TARGET)
    }
  end

  private

  def normalize_value
    self.value = value&.strip&.downcase&.gsub(/\s+/, "")
  end

  def set_subdomain_defaults
    self.dns_status = :dns_verified       # subdomains are auto-verified (wildcard DNS)
    self.ssl_status = :ssl_active         # covered by *.helpbolic.com wildcard cert
    self.cname_target = ""

    # Append suffix if not already present
    unless value&.end_with?(SUBDOMAIN_SUFFIX)
      self.value = "#{value}#{SUBDOMAIN_SUFFIX}" if value.present?
    end
  end

  def set_custom_domain_defaults
    self.cname_target = CNAME_TARGET

    # Only set initial statuses on new records if not explicitly set
    if new_record?
      self.dns_status = :dns_unverified unless dns_status_changed?
      self.ssl_status = :ssl_none unless ssl_status_changed?
    end
  end

  def value_not_reserved
    slug = subdomain_slug
    return if slug.blank?

    if RESERVED_SUBDOMAINS.include?(slug)
      errors.add(:value, :reserved, slug: slug)
    end
  end

  def value_is_valid_subdomain_format
    slug = value&.chomp(SUBDOMAIN_SUFFIX)
    return if slug.blank?

    if slug.length < MIN_SUBDOMAIN_LENGTH
      errors.add(:value, :too_short, min: MIN_SUBDOMAIN_LENGTH)
      return
    end

    if slug.length > MAX_SUBDOMAIN_LENGTH
      errors.add(:value, :too_long, max: MAX_SUBDOMAIN_LENGTH)
      return
    end

    unless slug.match?(/\A[a-z0-9]([a-z0-9\-]*[a-z0-9])?\z/)
      errors.add(:value, :invalid_subdomain_format)
    end
  end

  def value_is_valid_custom_domain_format
    return if value.blank?

    unless value.match?(/\A([a-z0-9]([a-z0-9\-]*[a-z0-9])?\.)+[a-z]{2,}\z/i)
      errors.add(:value, :invalid_custom_domain_format)
    end

    if value.end_with?(SUBDOMAIN_SUFFIX)
      errors.add(:value, :helpbolic_subdomain_as_custom)
    end
  end

  def account_custom_domain_limit
    return unless account

    if account.respond_to?(:limit_reached?) && account.limit_reached?(:custom_domains)
      errors.add(:base, :custom_domain_limit_reached)
    end
  end
end

