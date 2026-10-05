require 'rails_helper'

RSpec.describe Automations::ContentRenderer do
  let(:account) { create(:account, name: 'Acme') }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:agent) { create(:user, first_name: 'Sara', last_name: 'Khan') }

  def render(content, actor: agent)
    described_class.call(content: content, conversation: conversation, account: account, actor: actor)
  end

  it 'returns content untouched when there are no variables' do
    expect(render('Plain text')).to eq('Plain text')
  end

  it 'renders agent, account and conversation variables' do
    output = render('{{ agent.first_name }} from {{ account.name }} re #{{ conversation.identifier }}')
    expect(output).to eq("Sara from Acme re ##{conversation.identifier}")
  end

  it 'renders blank strings for missing people instead of raising' do
    expect(render('Hi {{ agent.name }}!', actor: nil)).to eq('Hi !')
  end

  it 'falls back to raw content on template syntax errors' do
    expect(render('Broken {{ agent.name')).to eq('Broken {{ agent.name')
  end
end
