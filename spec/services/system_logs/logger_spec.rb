require 'rails_helper'

RSpec.describe SystemLogs::Logger do
  let(:account) { double('Account') }
  let(:service) do
    described_class.new(
      event_key: 'login_failed',
      level: :warning,
      account: account,
      message: 'Invalid password',
      payload: { user_id: 1 },
      metadata: { source: 'web' }
    )
  end

  describe '#call' do
    before do
      stub_const('SystemLog', double('SystemLogClass'))
      
      allow(Current).to receive(:try).with(:ip_address).and_return('127.0.0.1')
      allow(Current).to receive(:try).with(:user_agent).and_return('Mozilla')
      allow(Current).to receive(:try).with(:request_id).and_return('req-123')
    end

    it 'logs event with system log and current context' do
      expect(SystemLog).to receive(:log_event).with(
        'login_failed',
        level: :warning,
        account: account,
        message: 'Invalid password',
        payload: { user_id: 1 },
        metadata: {
          source: 'web',
          remote_ip: '127.0.0.1',
          user_agent: 'Mozilla',
          request_id: 'req-123'
        }
      )

      service.call
    end
  end
end
