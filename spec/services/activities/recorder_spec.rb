require 'rails_helper'

RSpec.describe Activities::Recorder do
  let(:account) { double('Account', id: 5) }
  let(:trackable) { double('Trackable', class: double(name: 'Article'), id: 10, account: account, attributes: { 'title' => 'Old' }) }
  let(:actor) { double('Actor', class: double(name: 'User'), id: 1) }

  describe '#call' do
    before do
      stub_const('ActivityLogWorker', double('ActivityLogWorkerClass'))
      
      allow(Current).to receive(:user).and_return(actor)
      allow(Current).to receive(:ip_address).and_return('1.2.3.4')
      allow(Current).to receive(:user_agent).and_return('Safari')
      allow(Current).to receive(:request_id).and_return('req-999')
    end

    context 'with minimal parameters' do
      let(:service) { described_class.new(trackable: trackable, event_type: :updated) }

      it 'enqueues activity log worker with attributes snapshot' do
        expect(ActivityLogWorker).to receive(:perform_async).with(
          5,
          hash_including(
            "trackable_type" => "Article",
            "trackable_id" => 10,
            "event_type" => "updated",
            "actor_type" => "User",
            "actor_id" => 1,
            "changes" => {},
            "snapshot" => { "title" => "Old" },
            "metadata" => {
              "remote_ip" => "1.2.3.4",
              "user_agent" => "Safari",
              "request_id" => "req-999"
            }
          )
        )

        service.call
      end
    end

    context 'with explicit changes and custom payload methods' do
      let(:trackable) do
        double('Trackable', 
          class: double(name: 'Article'), 
          id: 10, 
          account: account,
          changes_payload: { 'title' => ['Old', 'New'] },
          snapshot_payload: { 'title' => 'New', 'body' => 'Text' }
        )
      end
      let(:service) { described_class.new(trackable: trackable, event_type: :updated, changes: { 'custom' => 'change' }) }

      it 'prefers explicit changes and snapshot_payload' do
        expect(ActivityLogWorker).to receive(:perform_async).with(
          5,
          hash_including(
            "changes" => { "custom" => "change" },
            "snapshot" => { "title" => "New", "body" => "Text" }
          )
        )

        service.call
      end
    end

    it 'skips if account is missing' do
      allow(trackable).to receive(:account).and_return(nil)
      allow(trackable).to receive(:inbox).and_return(nil)
      
      service = described_class.new(trackable: trackable, event_type: :updated)
      
      expect(ActivityLogWorker).not_to receive(:perform_async)
      service.call
    end
  end
end
