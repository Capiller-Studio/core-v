# == Schema Information
#
# Table name: inbox_teams
#
#  id         :uuid             not null, primary key
#  inbox_id   :uuid             not null
#  team_id    :uuid             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_inbox_teams_on_inbox_id              (inbox_id)
#  index_inbox_teams_on_inbox_id_and_team_id  (inbox_id,team_id) UNIQUE
#  index_inbox_teams_on_team_id               (team_id)
#

FactoryBot.define do
  factory :inbox_team do
    inbox
    team
  end
end
