# frozen_string_literal: true

class DetectLanguageWorker < BaseMutexWorker
  sidekiq_options queue: :default

  def perform(account_id, message_id)
    account = Account.find_by(id: account_id)
    return unless account
    
    account.with_shard do
      message = account.messages.find_by(id: message_id)
      return unless message
      
      customer = message.sender
      return unless customer.is_a?(Customer)
      
      # Do not overwrite if it's already explicitly set to a non-English language
      return unless customer.locale.blank? || customer.locale == "en"

      lock_key = RedisUtilities::Keys::LANGUAGE_DETECTION_LOCK % { account_id: account_id, conversation_id: message.conversation_id }

      ::RedisUtilities::MutexHelpers.with_lock(lock_key) do
        # Verify it's the first customer message to avoid processing duplicates
        first_customer_msg = message.conversation.messages.where(sender_type: 'Customer').order(:created_at).first
        return unless first_customer_msg&.id == message.id

        detected_locale = ::Utilities::LocaleParser.parse(Integrations::LanguageDetectors::Engine.call(
          text: message.content, 
          account: account
        ))
        
        return if detected_locale.blank?
        return if detected_locale == "en" && customer.locale == "en"

        # Save to customer and conversation
        customer.update!(locale: detected_locale)
        message.conversation.update!(locale: detected_locale)
      end
    end
  rescue StandardError => e
    raise(e) if e.is_a?(MutexLockError)
    Rails.logger.error("DetectLanguageWorker Error for Message #{message_id}: #{e.message}")
  end
end
