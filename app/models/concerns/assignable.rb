# frozen_string_literal: true

module Assignable
  extend ActiveSupport::Concern

  included do
    after_create_commit :auto_assign_agent, if: :should_auto_assign?
  end

  # --- Agent Assignment ---

  def assigned?
    assignee_id.present?
  end

  def assign!(user)
    with_lock do
      return if assignee_id == user&.id

      old_assignee_id = assignee_id
      update!(assignee: user)

      # Ensure assignee is added as a participant so they can track unread/seen states
      conversation_members.find_or_create_by!(member: user, account: account) do |cm|
        cm.role = :participant
      end

      if saved_change_to_assignee_id?
        # Notify the assigned user
        Notification.create(
          account: account,
          user: user,
          resource: self,
          event: :conversation_assigned
        )

        # Record the activity
        Activities::Recorder.call(
          trackable: self,
          event_type: :conversation_assigned,
          changes: { assignee_id: [old_assignee_id, user.id] },
          actor: Current.user || user
        )
      end
    end
  end

  def unassign!
    with_lock do
      return if assignee_id.nil?

      old_assignee_id = assignee_id
      update!(assignee: nil)
      
      if saved_change_to_assignee_id?
        Activities::Recorder.call(
          trackable: self,
          event_type: :conversation_unassigned,
          changes: { assignee_id: [old_assignee_id, nil] },
          actor: Current.user
        )
      end
    end
  end

  # --- Team Assignment ---

  def assign_team!(team)
    with_lock do
      return if team_id == team&.id

      old_team_id = team_id
      update!(team: team)

      if saved_change_to_team_id?
        # Notify team members that a new conversation is assigned to their team
        notifiable_agents.each do |user|
          Notification.create(
            account: account,
            user: user,
            resource: self,
            event: :team_assigned
          )
        end

        # Record the activity
        Activities::Recorder.call(
          trackable: self,
          event_type: :team_assigned,
          changes: { team_id: [old_team_id, team.id] },
          actor: Current.user
        )
      end
    end
  end

  def unassign_team!
    with_lock do
      return if team_id.nil?

      old_team_id = team_id
      update!(team: nil)

      if saved_change_to_team_id?
        # Record the activity
        Activities::Recorder.call(
          trackable: self,
          event_type: :team_unassigned,
          changes: { team_id: [old_team_id, nil] },
          actor: Current.user
        )
      end
    end
  end

  def team_assigned?
    team_id.present?
  end

  private

  def should_auto_assign?
    inbox.auto_assign?
  end

  def auto_assign_agent
    AssignmentPolicies::Dispatcher.call(conversation: self)
  end
end
