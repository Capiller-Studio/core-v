# frozen_string_literal: true

require 'openai'

module Ai
  class Client < ApplicationService
    MODELS = {
      lite: "gpt-5.6-luna",
      base: "gpt-5.4-mini",
      embedding: "text-embedding-3-small"
    }.freeze

    COSTS = {
      lite: 1,
      base: 3
    }.freeze

    def initialize(account:, action_type:, user: nil, model: :lite, system_prompt: nil, messages: [], response_format: nil)
      @account = account
      @action_type = action_type
      @user = user
      @model_key = model
      @model_name = MODELS.fetch(model, MODELS[:lite])
      @system_prompt = system_prompt
      @messages = messages
      @response_format = response_format
      
      # Determine credit cost from centralized COSTS constant
      @cost = COSTS.fetch(model, 1)
    end

    def call
      # 1. Deduct AI Credits BEFORE making the API call to prevent negative races
      Ai::CreditManager.call(
        account: @account, 
        action_type: @action_type, 
        model_used: @model_name, 
        user: @user, 
        cost: @cost
      )

      # 2. Build Message Payload
      payload = build_payload

      # 3. Call OpenAI
      client = ::OpenAI::Client.new
      params = {
        model: @model_name,
        messages: payload,
        max_completion_tokens: 1500
      }
      params[:response_format] = { type: @response_format } if @response_format.present?

      response = client.chat(parameters: params)

      # 4. Return the parsed response content
      response.dig("choices", 0, "message", "content")
    rescue AiInsufficientBalanceError => e
      raise e # Re-raise so the controller can handle it (e.g., render 402 Payment Required)
    rescue => e
      # If OpenAI fails, ideally we should refund the credit here!
      refund_credit!
      raise e
    end

    private

    TOTAL_MAX_CHARS = 50_000 # Total budget across system prompt and all messages

    def build_payload
      payload = []
      budget = TOTAL_MAX_CHARS

      if @system_prompt.present?
        sys_content = truncate_text(@system_prompt, budget)
        payload << { role: "system", content: sys_content }
        budget -= sys_content.length
      end
      
      truncated_messages = []
      
      # Process from newest to oldest to preserve most relevant context
      @messages.reverse_each do |msg|
        break if budget <= 0
        
        msg_content = msg[:content]
        if msg_content.is_a?(String)
          truncated = truncate_text(msg_content, budget)
          budget -= truncated.length
          # Prepend because we are iterating in reverse
          truncated_messages.unshift({ role: msg[:role], content: truncated })
        else
          truncated_messages.unshift(msg) # Ignore non-string sizes (e.g., images)
        end
      end

      payload + truncated_messages
    end

    def truncate_text(text, max_length)
      return text unless text.is_a?(String)
      return text if max_length <= 0
      text.length > max_length ? text[0...max_length] + "... [TRUNCATED]" : text
    end

    def refund_credit!
      Ai::CreditManager.refund!(
        account: @account,
        amount: @cost,
        action_type: @action_type
      )
    end
  end
end
