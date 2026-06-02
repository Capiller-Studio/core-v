# frozen_string_literal: true

module Csat
  module Surveys
    class CreateService < ApplicationService
      attr_reader :account, :params

      def initialize(account, params)
        @account = account
        @params = params
      end

      def call
        account.with_shard do
          ShardRecord.transaction do
            csat_survey = Csat::Survey.new(params)
            csat_survey.account = account
            csat_survey.save!
            csat_survey
          end
        end
      end
    end
  end
end
