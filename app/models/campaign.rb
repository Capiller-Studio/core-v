# frozen_string_literal: true

# == Schema Information
#
# Table name: campaigns
#
#  id                :uuid             not null, primary key
#  campaign_type     :integer          default("one_time"), not null
#  conditions        :jsonb            not null
#  description       :text
#  end_at            :datetime
#  name              :string
#  start_at          :datetime
#  status            :integer          default("active"), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :uuid             not null
#  email_template_id :uuid
#  user_id           :uuid
#
# Indexes
#
#  index_campaigns_on_account_id                    (account_id)
#  index_campaigns_on_account_id_and_campaign_type  (account_id,campaign_type)
#  index_campaigns_on_account_id_and_created_at     (account_id,created_at)
#  index_campaigns_on_account_id_and_name           (account_id,name)
#  index_campaigns_on_account_id_and_start_at       (account_id,start_at)
#  index_campaigns_on_account_id_and_status         (account_id,status)
#
# Foreign Keys
#
#  fk_rails_...  (email_template_id => email_templates.id) ON DELETE => nullify
#
# NOTE: This model is currently unimplemented and unused.
# Its database migration has been moved to db/archived_migrations/
class Campaign < ShardRecord
  belongs_to :user
  belongs_to :account

  enum :status, { active: 0 }
  enum :campaign_type, { one_time: 0 }
end
