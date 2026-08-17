# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SlaTrackable, type: :model do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }

  describe 'SLA associations and hooks' do
    it 'associates conversation with conversation_slas' do
      conversation = create(:conversation, account: account, inbox: inbox)
      sla_policy = create(:sla_policy, account: account)
      conv_sla = create(:conversation_sla, conversation: conversation, sla_policy: sla_policy)

      expect(conversation.conversation_slas).to include(conv_sla)
      expect(conversation.sla_policies).to include(sla_policy)
    end
  end
end
