# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :webhooks do
    get "instagram", to: "instagram#hub"
    post "instagram", to: "instagram#index"
    post "paddle", to: "paddle#create"
    post "stripe", to: "stripe#create"

    namespace :sms do
      post "aws_sns/:account_id/:channel_id", to: "aws_sns#create"
      post "signalwire/:account_id/:channel_id", to: "signalwire#create"
      post "twilio/:account_id/:channel_id", to: "twilio#create"
    end
  end
end
