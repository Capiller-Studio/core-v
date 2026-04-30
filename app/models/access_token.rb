# frozen_string_literal: true

# == Schema Information
#
# Table name: access_tokens
#
#  id                :uuid             not null, primary key
#  destroy_after_use :boolean          default(FALSE), not null
#  flags             :integer          default(0), not null
#  owner_type        :string           not null
#  token             :string           not null
#  token_type        :integer          default("api_key"), not null
#  valid_till        :datetime
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  owner_id          :uuid             not null
#
# Indexes
#
#  index_access_tokens_on_created_at   (created_at)
#  index_access_tokens_on_owner        (owner_type,owner_id)
#  index_access_tokens_on_token        (token) UNIQUE
#  index_access_tokens_on_token_type   (token_type)
#
class AccessToken < ApplicationRecord
  belongs_to :owner, polymorphic: true

  # api_key    — long-lived token used for API authentication (Users, Accounts)
  # magic_link — short-lived, one-time-use token for customer portal login via email
  enum :token_type, { api_key: 0, magic_link: 1 }
end
