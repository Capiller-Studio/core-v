# frozen_string_literal: true

module Ai
  class ToneRewriter < ApplicationService
    TONES = %w[professional friendly empathetic concise formal].freeze

    def initialize(text:, tone:, account:, user:)
      @text = text
      @tone = tone
      @account = account
      @user = user
    end

    def call
      return @text unless TONES.include?(@tone)

      Ai::Client.call(
        account: @account,
        user: @user,
        action_type: "tone_rewrite",
        model: :lite,
        system_prompt: "Rewrite the following text in a #{@tone} tone. Output ONLY the rewritten text.",
        messages: [{ role: "user", content: @text }]
      )
    end
  end
end
