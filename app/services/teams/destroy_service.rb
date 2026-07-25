# frozen_string_literal: true

module Teams
  class DestroyService < ApplicationService
    attr_reader :team

    def initialize(team:)
      @team = team
    end

    def call
      validate_feature_gate!

      ShardRecord.transaction do
        # Nullify team_id on all conversations before destroying
        # This is handled by `dependent: :nullify` on the Team model,
        # but we do it explicitly for clarity and to avoid N+1 callbacks.
        # rubocop:disable Rails/SkipsModelValidations
        team.conversations.update_all(team_id: nil)
        # rubocop:enable Rails/SkipsModelValidations

        team.destroy!
      end
    end

    private

    def validate_feature_gate!
      return if team.account.feature_enabled?(:teams)

      raise(ActiveRecord::RecordNotSaved, "Teams feature is not enabled for this account")
    end
  end
end
