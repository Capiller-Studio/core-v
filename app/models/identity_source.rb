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
  include UsageTrackable

  belongs_to :account

  enum :source_type, { api: 0 }
  
  validate :validate_source_url_safety

  before_validation :ensure_json_defaults

  tracks_usage :identity_sources

  private

  def ensure_json_defaults
    self.headers ||= {}
    self.params ||= {}
    self.response_mapping ||= {}
    self.configurations ||= {}
  end

  def validate_source_url_safety
    return if source_url.blank?

    result = Security::UrlValidator.validate(source_url)
    errors.add(:source_url, result[:error]) unless result[:valid]
  end
end
