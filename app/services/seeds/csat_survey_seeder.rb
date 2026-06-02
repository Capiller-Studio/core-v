# frozen_string_literal: true

module Seeds
  class CsatSurveySeeder
    def self.seed(account)
      new(account).seed
    end

    def initialize(account)
      @account = account
    end

    def seed
      account.with_shard do
        # Find the system default email template for CSAT (might be inactive)
        email_template = account.email_templates.find_by(name: "csat_survey")

        csat_survey = Csat::Survey.find_or_initialize_by(account: account, name: "Default CSAT Survey")
        csat_survey.email_template = email_template
        csat_survey.save!

        # Seed translation for the account's primary locale
        [account.locale.to_sym].each do |locale|
          next if csat_survey.translated_to?(locale)

          csat_survey.translations.create!(
            locale: locale.to_s,
            prompt: "How would you rate the support you received?",
            portal_title: "How did we do?",
            portal_subtitle: "We'd love to hear your feedback on your recent support experience.",
            portal_feedback_label: "Tell us more (Optional)"
          )
        end
      end
    end

    private

    attr_reader :account
  end
end
