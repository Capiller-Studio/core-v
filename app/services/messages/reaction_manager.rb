# frozen_string_literal: true

module Messages
  class ReactionManager < ApplicationService
    attr_accessor :message, :sender, :emoji, :action, :reaction_name, :external_id

    def initialize(message:, sender:, emoji:, action: :react, reaction_name: nil, external_id: nil)
      self.message       = message
      self.sender        = sender
      self.emoji         = emoji
      self.action        = action.to_sym
      self.reaction_name = reaction_name
      self.external_id   = external_id
    end

    def call
      return unless message && sender

      case action
      when :react
        handle_react
      when :unreact
        handle_unreact
      end
    end

    private

    def handle_react
      return if emoji.blank?

      reaction = message.reactions.find_or_initialize_by(
        account: message.account,
        sender: sender,
        emoji: emoji
      )
      reaction.reaction_name = reaction_name if reaction_name.present?
      reaction.external_id   = external_id if external_id.present?
      
      if reaction.save
        message.broadcast_message_update
      end
      reaction
    end

    def handle_unreact
      scope = message.reactions.where(sender: sender)
      scope = scope.where(emoji: emoji) if emoji.present?
      
      if scope.destroy_all.any?
        message.broadcast_message_update
      end
    end
  end
end
