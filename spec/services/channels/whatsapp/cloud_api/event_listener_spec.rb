# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Channels::Whatsapp::CloudApi::EventListener do
  let(:whatsapp_channel) { double('Channel::Whatsapp', id: 5, account: account, account_id: 1) }
  let(:account) { double('Account', id: 1) }

  before do
    allow(account).to receive(:with_shard).and_yield
  end

  describe '#call' do
    context 'when parsing statuses' do
      let(:params) do
        {
          entry: [
            {
              "changes" => [
                {
                  "value" => {
                    statuses: [
                      { id: "wa_msg_1", status: "read" }
                    ]
                  }
                }
              ]
            }
          ]
        }
      end

      let(:service) { described_class.new(whatsapp_channel: whatsapp_channel, params: params, account: account) }

      it 'enqueues status update worker' do
        stub_const('Messages::StatusUpdateWorker', double('Worker'))

        expect(Messages::StatusUpdateWorker).to receive(:perform_async).with(
          1,
          "read",
          hash_including("external_ids" => ["wa_msg_1"])
        )

        service.call
      end

      it 'processes multiple statuses in a single batch without dropping any' do
        batch_params = {
          entry: [
            {
              changes: [
                {
                  value: {
                    statuses: [
                      { id: "wa_msg_1", status: "delivered" },
                      { id: "wa_msg_2", status: "read" },
                      { id: "wa_msg_3", status: "failed", errors: [{ code: 131051, title: "Message expired" }] }
                    ]
                  }
                }
              ]
            }
          ]
        }

        stub_const('Messages::StatusUpdateWorker', double('Worker'))

        expect(Messages::StatusUpdateWorker).to receive(:perform_async).with(
          1,
          "delivered",
          hash_including("external_ids" => ["wa_msg_1"])
        )

        expect(Messages::StatusUpdateWorker).to receive(:perform_async).with(
          1,
          "read",
          hash_including("external_ids" => ["wa_msg_2"])
        )

        expect(Messages::StatusUpdateWorker).to receive(:perform_async).with(
          1,
          "failed",
          hash_including(
            "external_ids" => ["wa_msg_3"],
            "error_code" => 131051,
            "error_message" => "Message expired"
          )
        )

        described_class.new(whatsapp_channel: whatsapp_channel, params: batch_params, account: account).call
      end

      it 'skips status elements with missing id or status' do
        malformed_params = {
          entry: [
            {
              changes: [
                {
                  value: {
                    statuses: [
                      { id: nil, status: "read" },
                      { id: "wa_msg_valid", status: "delivered" },
                      { id: "wa_msg_no_status", status: nil }
                    ]
                  }
                }
              ]
            }
          ]
        }

        stub_const('Messages::StatusUpdateWorker', double('Worker'))

        expect(Messages::StatusUpdateWorker).to receive(:perform_async).once.with(
          1,
          "delivered",
          hash_including("external_ids" => ["wa_msg_valid"])
        )

        described_class.new(whatsapp_channel: whatsapp_channel, params: malformed_params, account: account).call
      end
    end

    context 'when parsing messages' do
      let(:params) do
        {
          entry: [
            {
              "changes" => [
                {
                  "value" => {
                    messages: [
                      { id: "wa_msg_2" }
                    ]
                  }
                }
              ]
            }
          ]
        }
      end

      let(:service) { described_class.new(whatsapp_channel: whatsapp_channel, params: params, account: account) }

      it 'calls ConversationCreator' do
        stub_const('Channels::Whatsapp::CloudApi::ConversationCreator', double('Creator'))

        expect(Channels::Whatsapp::CloudApi::ConversationCreator).to receive(:call).with(
          whatsapp_channel: whatsapp_channel,
          parsed_params: { messages: [{ id: "wa_msg_2" }] },
          account: account
        )

        service.call
      end

      it 'parses payloads with string keys identically to symbol keys' do
        string_payload = {
          "entry" => [
            {
              "changes" => [
                {
                  "value" => {
                    "messages" => [{ "id" => "wa_msg_str" }]
                  }
                }
              ]
            }
          ]
        }

        stub_const('Channels::Whatsapp::CloudApi::ConversationCreator', double('Creator'))

        expect(Channels::Whatsapp::CloudApi::ConversationCreator).to receive(:call).with(
          whatsapp_channel: whatsapp_channel,
          parsed_params: hash_including("messages" => [{ "id" => "wa_msg_str" }]),
          account: account
        )

        described_class.new(whatsapp_channel: whatsapp_channel, params: string_payload, account: account).call
      end
    end

    context 'with edge cases and malformed payloads' do
      it 'handles completely empty params gracefully without raising' do
        expect { described_class.new(whatsapp_channel: whatsapp_channel, params: {}, account: account).call }.not_to raise_error
      end

      it 'handles nil entry gracefully without raising' do
        expect { described_class.new(whatsapp_channel: whatsapp_channel, params: { entry: nil }, account: account).call }.not_to raise_error
      end

      it 'handles empty changes gracefully without raising' do
        expect { described_class.new(whatsapp_channel: whatsapp_channel, params: { entry: [{ changes: [] }] }, account: account).call }.not_to raise_error
      end

      it 'rescues and logs standard errors during call' do
        allow(account).to receive(:with_shard).and_raise(StandardError.new("Shard connection timeout"))
        expect(Rails.logger).to receive(:error).with(/WhatsApp EventListener error: Shard connection timeout/)
        allow(Rails.logger).to receive(:error)

        expect { described_class.new(whatsapp_channel: whatsapp_channel, params: {}, account: account).call }.not_to raise_error
      end
    end
  end
end
