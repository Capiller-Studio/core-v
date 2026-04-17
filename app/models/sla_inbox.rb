# frozen_string_literal: true

# == Schema Information
#
# Table name: sla_inboxes
#
#  id            :uuid             not null, primary key
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :uuid             not null
#  inbox_id      :uuid             not null
#  sla_policy_id :uuid             not null
#
# Indexes
#
#  index_sla_inboxes_on_account_id                    (account_id)
#  index_sla_inboxes_on_inbox_id                      (inbox_id)
#  index_sla_inboxes_on_sla_policy_id                 (sla_policy_id)
#  index_sla_inboxes_on_sla_policy_id_and_inbox_id    (sla_policy_id,inbox_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (inbox_id => inboxes.id) ON DELETE => cascade
#  fk_rails_...  (sla_policy_id => sla_policies.id) ON DELETE => cascade
#
class SlaInbox < ShardRecord
  belongs_to :account
  belongs_to :sla_policy
  belongs_to :inbox
end
