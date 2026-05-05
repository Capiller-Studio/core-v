# frozen_string_literal: true

module Assignable
  extend ActiveSupport::Concern

  included do
    after_create_commit :auto_assign_agent, if: :should_auto_assign?
  end

  def assignee
    conversation_members.assignees.agents.first&.member
  end

  def assigned?
    conversation_members.assignees.agents.exists?
  end

  def assign!(user)
    ActiveRecord::Base.transaction do
      # Demote current assignee to participant
      # rubocop:disable Rails/SkipsModelValidations
      conversation_members.assignees.agents.update_all(role: :participant)
      # rubocop:enable Rails/SkipsModelValidations

      # Set new assignee
      member = conversation_members.find_or_initialize_by(
        member: user,
        account:
      )
      member.update!(role: :assignee)
    end
  end

  def unassign!
    # rubocop:disable Rails/SkipsModelValidations
    conversation_members.assignees.agents.update_all(role: :participant)
    # rubocop:enable Rails/SkipsModelValidations
  end

  private

  def should_auto_assign?
    inbox.auto_assign?
  end

  def auto_assign_agent
    Conversations::RoundRobinAssignment.call(conversation: self)
  end
end
