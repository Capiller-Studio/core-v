require 'rails_helper'

RSpec.describe Seeds::CsatSurveySeeder do
  let(:account) { create(:account, locale: 'en') }
  let!(:email_template) { create(:email_template, account: account, name: 'csat_survey') }

  describe '.seed' do
    it 'creates a CSAT Survey with translations in a shard block' do
      expect {
        described_class.seed(account)
      }.to change { Csat::Survey.count }.by(1)
       .and change { Csat::SurveyTranslation.count }.by(1)

      account.with_shard do
        survey = Csat::Survey.find_by(account: account)
        expect(survey.name).to eq('Default CSAT Survey')
        expect(survey.email_template).to eq(email_template)
        expect(survey.account).to eq(account)

        translation = survey.translations.find_by(locale: 'en')
        expect(translation.prompt).to eq('How would you rate the support you received?')
        expect(translation.portal_title).to eq('How did we do?')
        expect(translation.portal_subtitle).to eq("We'd love to hear your feedback on your recent support experience.")
        expect(translation.portal_feedback_label).to eq('Tell us more (Optional)')
      end
    end

    it 'is idempotent' do
      described_class.seed(account)

      expect {
        described_class.seed(account)
      }.to change { Csat::Survey.count }.by(0)
       .and change { Csat::SurveyTranslation.count }.by(0)
    end
  end
end
