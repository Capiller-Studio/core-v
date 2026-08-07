# frozen_string_literal: true

module Ai
  class Agent < ShardRecord
    include Translateable

    TRANSLATABLE_FIELDS = %i[greeting_message handoff_message fallback_message].freeze
    translates(*TRANSLATABLE_FIELDS)

    belongs_to :account
    belongs_to :portal, class_name: "HelpCenter::Portal", optional: true
    has_many :inboxes, foreign_key: 'ai_agent_id', dependent: :nullify

    enum :status, { active: 0, inactive: 1 }
    enum :agent_type, { help_center_bot: 0, custom: 1 }
    enum :tone, { professional: 0, friendly: 1, neutral: 2, concise: 3 }

    validates :name, presence: true
    validates :max_exchanges, numericality: { greater_than: 0, less_than_or_equal_to: 20 }
    validates :confidence_threshold, numericality: { greater_than_or_equal_to: 0.0, less_than_or_equal_to: 1.0 }

    def active_and_configured?
      active?
    end

    def resolution_rate
      return 0 if total_conversations.zero?

      (total_resolutions.to_f / total_conversations * 100).round(1)
    end

    def handoff_rate
      return 0 if total_conversations.zero?

      (total_handoffs.to_f / total_conversations * 100).round(1)
    end

    def event_payload
      {
        id: id,
        name: name,
        type: "ai_agent"
      }
    end
  end
end
