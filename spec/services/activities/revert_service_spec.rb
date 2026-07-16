require 'rails_helper'

RSpec.describe Activities::RevertService do
  let(:trackable) { double('Trackable') }
  let(:activity) { double('Activity', id: 50, trackable: trackable) }

  describe '#call' do
    before do
      stub_const('Activities::Recorder', double('RecorderClass'))
      allow(trackable).to receive(:transaction).and_yield
      allow(trackable).to receive(:save!)
    end

    context 'when mode is :rollback' do
      let(:service) { described_class.new(activity: activity, mode: :rollback) }

      it 'applies full rollback and logs reversion' do
        snapshot = { "title" => "Old Title", "status" => "draft", "translations" => [] }
        allow(activity).to receive(:object_snapshot).and_return(snapshot)

        expect(trackable).to receive(:assign_attributes).with({ "title" => "Old Title", "status" => "draft" })
        expect(trackable).to receive(:respond_to?).with(:translations).and_return(false)

        expect(Activities::Recorder).to receive(:call).with(
          trackable: trackable,
          event_type: :rolled_back,
          changes: { "target_activity_id" => 50, "reversion_mode" => :rollback }
        )

        expect(service.call).to be true
      end
    end

    context 'when mode is :undo' do
      let(:service) { described_class.new(activity: activity, mode: :undo) }

      it 'applies selective undo and logs reversion' do
        changes = { "title" => ["Old", "New"], "status" => ["draft", "published"] }
        allow(activity).to receive(:object_changes).and_return(changes)

        expect(trackable).to receive(:respond_to?).with("title=").and_return(true)
        expect(trackable).to receive(:title=).with("Old")
        
        expect(trackable).to receive(:respond_to?).with("status=").and_return(true)
        expect(trackable).to receive(:status=).with("draft")

        expect(Activities::Recorder).to receive(:call).with(
          trackable: trackable,
          event_type: :undone,
          changes: { "target_activity_id" => 50, "reversion_mode" => :undo }
        )

        expect(service.call).to be true
      end
    end

    context 'when error occurs' do
      let(:service) { described_class.new(activity: activity) }

      it 'rescues and returns false' do
        allow(activity).to receive(:object_changes).and_raise(StandardError.new("DB Error"))
        
        expect(Rails.logger).to receive(:error).with(/Activities::RevertService Error: DB Error/)
        expect(service.call).to be false
      end
    end
  end
end
