# frozen_string_literal: true

module Accounts
  module Invitations
    class Update < ApplicationService
      attr_accessor :invitation, :role_ids

      def initialize(invitation:, role_ids:)
        self.invitation = invitation
        self.role_ids = role_ids
      end

      def call
        return false unless invitation.pending?

        invitation.update!(role_ids: role_ids)
      end
    end
  end
end
