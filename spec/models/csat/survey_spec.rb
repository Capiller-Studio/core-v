# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Csat::Survey, type: :model do
  let(:account) { create(:account) }

  describe 'associations and validations' do
    it 'validates presence of name' do
      account.with_shard do
        survey = build(:csat_survey, account: account, name: nil)
        expect(survey).not_to be_valid
        expect(survey.errors[:name]).to include("can't be blank")
      end
    end
  end

  describe '#render_prompt' do
    it 'renders Liquid templates with variables' do
      account.with_shard do
        survey = create(:csat_survey, account: account, name: 'Support Survey', prompt: 'Hi {{ customer.name }}, please rate our service!')
        result = survey.render_prompt(customer: { name: 'Alice' })
        expect(result).to eq('Hi Alice, please rate our service!')
      end
    end

    it 'returns empty string when prompt is blank' do
      account.with_shard do
        survey = create(:csat_survey, account: account, name: 'Blank Prompt', prompt: nil)
        expect(survey.render_prompt).to eq('')
      end
    end
  end
end
