# frozen_string_literal: true

class InboxTeam < ShardRecord
  belongs_to :inbox
  belongs_to :team

  validates :team_id, uniqueness: { scope: :inbox_id }
end
