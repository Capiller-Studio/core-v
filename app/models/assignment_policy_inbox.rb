# frozen_string_literal: true

# == Schema Information
#
# Table name: assignment_policy_inboxes
#
#  id                   :uuid             not null, primary key
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  account_id           :uuid             not null
#  assignment_policy_id :uuid             not null
#  inbox_id             :uuid             not null
#
# Indexes
#
#  idx_ap_inbox_unique                                  (assignment_policy_id,inbox_id) UNIQUE
#  index_assignment_policy_inboxes_on_account_id        (account_id)
#  index_assignment_policy_inboxes_on_assignment_policy_id (assignment_policy_id)
#  index_assignment_policy_inboxes_on_inbox_id          (inbox_id)
#
# Foreign Keys
#
#  fk_rails_...  (assignment_policy_id => assignment_policies.id) ON DELETE => cascade
#  fk_rails_...  (inbox_id => inboxes.id) ON DELETE => cascade
#
class AssignmentPolicyInbox < ShardRecord
  belongs_to :assignment_policy
  belongs_to :inbox
  belongs_to :account

  validates :inbox_id, uniqueness: { scope: :assignment_policy_id }
end
