# frozen_string_literal: true

# == Schema Information
#
# Table name: identity_sources
#
#  id               :uuid             not null, primary key
#  configurations   :jsonb            not null
#  description      :text
#  headers          :jsonb            not null
#  name             :string           not null
#  params           :jsonb            not null
#  response_mapping :jsonb            not null
#  source_type      :integer          default("api"), not null
#  source_url       :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  account_id       :uuid             not null
#
# Indexes
#
#  index_identity_sources_on_account_id                 (account_id)
#  index_identity_sources_on_account_id_and_created_at  (account_id,created_at)
#  index_identity_sources_on_account_id_and_name        (account_id,name)
#
class IdentitySource < ShardRecord
  belongs_to :account

  enum :source_type, { api: 0 }
  
  validate :validate_source_url_safety

  before_validation :ensure_json_defaults

  private

  def ensure_json_defaults
    self.headers ||= {}
    self.params ||= {}
    self.response_mapping ||= {}
    self.configurations ||= {}
  end

  def validate_source_url_safety
    return if source_url.blank?
    return if Rails.env.development? || Rails.env.test?

    begin
      uri = URI.parse(source_url)
      
      unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
        errors.add(:source_url, "must be a valid HTTP or HTTPS URL")
        return
      end

      forbidden_hosts = ['localhost', '127.0.0.1', '0.0.0.0', '::1']
      if forbidden_hosts.include?(uri.host) || uri.host.to_s.end_with?('.local') || uri.host.to_s.end_with?('.internal')
        errors.add(:source_url, "cannot be a local or private address")
      end
    rescue URI::InvalidURIError
      errors.add(:source_url, "is not a valid URL")
    end
  end
end
