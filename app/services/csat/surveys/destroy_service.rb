# frozen_string_literal: true

module Csat
  module Surveys
    class DestroyService < ApplicationService
      attr_reader :csat_survey

      def initialize(csat_survey)
        @csat_survey = csat_survey
      end

      def call
        csat_survey.account.with_shard do
          ShardRecord.transaction do
            csat_survey.destroy!
          end
        end
      end
    end
  end
end
