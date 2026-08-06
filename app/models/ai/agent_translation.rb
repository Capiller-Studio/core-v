# frozen_string_literal: true

module Ai
  class AgentTranslation < ShardRecord
    belongs_to :agent, class_name: "Ai::Agent"

    validates :locale, presence: true, uniqueness: { scope: :agent_id }
  end
end
