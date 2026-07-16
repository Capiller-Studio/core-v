require 'rails_helper'

RSpec.describe Automations::Actions::SendEmailToTeam do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:template) { create(:email_template, account: account) }
  let(:team) { create(:team, account: account) }

  describe '#call' do
    context 'when required params are missing' do
      it 'raises an error if email_template_id is missing' do
        service = described_class.new(resource: conversation, account: account, params: { team_id: team.id })
        expect { service.call }.to raise_error('email_template_id is required')
      end

      it 'raises an error if team_id is missing' do
        service = described_class.new(resource: conversation, account: account, params: { email_template_id: template.id })
        expect { service.call }.to raise_error('team_id is required')
      end
    end

    context 'with valid parameters' do
      let(:user1) { create(:user) }
      let(:user2) { create(:user) }
      let(:service) { described_class.new(resource: conversation, account: account, params: { email_template_id: template.id, team_id: team.id }) }

      before do
        create(:account_user, account: account, user: user1)
        create(:account_user, account: account, user: user2)
        create(:team_user, team: team, user: user1)
        create(:team_user, team: team, user: user2)
        stub_const('Automations::TeamEmailDeliveryWorker', double('TeamEmailDeliveryWorker', perform_async: true))
      end

      it 'enqueues a worker for each team user' do
        expect(Automations::TeamEmailDeliveryWorker).to receive(:perform_async).with(template.id, user1.id, conversation.id, account.id)
        expect(Automations::TeamEmailDeliveryWorker).to receive(:perform_async).with(template.id, user2.id, conversation.id, account.id)

        service.call
      end
    end
  end
end
