# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Integrations::Webhooks Comprehensive Edge Cases Suite', type: :service do
  let(:account) { create(:account, shard_key: 'de') }

  let(:webhook_integration) do
    create(:integration,
      account: account,
      provider: :webhook,
      status: :active,
      credentials: {
        'webhook_secret' => 'whsec_prod_supersecret_key_999'
      },
      settings: {
        'webhook_url' => 'https://example.com/api/webhooks'
      }
    )
  end

  let(:payload) { { event: 'conversation.created', conversation: { id: 101, status: 'open' } } }

  let(:delivery) do
    create(:webhook_delivery,
      account: account,
      resource: webhook_integration,
      event_name: 'conversation.created',
      endpoint_url: 'https://example.com/api/webhooks',
      request_payload: payload,
      status: :pending
    )
  end

  before do
    Webhook::Delivery.delete_all
    Webhook::DeliveryAttempt.delete_all
  end

  describe 'Integrations::Webhooks::BroadcasterWorker Edge Cases' do
    let(:worker) { Integrations::Webhooks::BroadcasterWorker.new }

    describe 'HMAC-SHA256 Signature Header Generation' do
      it 'computes exact cryptographic signature with timestamp and body when secret is present' do
        frozen_time = Time.at(1700000000)
        allow(Time).to receive(:now).and_return(frozen_time)

        expected_body = payload.to_json
        expected_secret = webhook_integration.webhook_secret
        expected_signature = OpenSSL::HMAC.hexdigest('SHA256', expected_secret, "#{frozen_time.to_i}-#{expected_body}")

        expect(HTTParty).to receive(:post).with(
          'https://example.com/api/webhooks',
          body: expected_body,
          headers: hash_including(
            'Content-Type' => 'application/json',
            'User-Agent' => 'Deskbolic-Webhook-Engine/1.0',
            'Signature' => "t=#{frozen_time.to_i},v1=#{expected_signature}"
          ),
          timeout: 10
        ).and_return(double('Response', success?: true, code: 200, body: '{"ok":true}'))

        worker.perform(account.id, delivery.id, 1)

        expect(delivery.reload).to be_successful
        expect(delivery.attempts.count).to eq(1)
        expect(delivery.attempts.first.http_status).to eq(200)
      end

      it 'omits Signature header entirely if integration webhook_secret is blank or nil' do
        webhook_integration.credentials['webhook_secret'] = ''
        webhook_integration.save!

        expect(HTTParty).to receive(:post) do |_url, opts|
          expect(opts[:headers]).not_to have_key('Signature')
          double('Response', success?: true, code: 200, body: 'OK')
        end

        worker.perform(account.id, delivery.id, 1)
        expect(delivery.reload).to be_successful
      end
    end

    describe 'Integration State & Provider Guards' do
      it 'skips dispatch and does not make HTTP call if integration is inactive or disconnected' do
        webhook_integration.update!(status: :disabled)
        expect(HTTParty).not_to receive(:post)

        worker.perform(account.id, delivery.id, 1)
        expect(delivery.reload).to be_pending
        expect(delivery.attempts.count).to eq(0)
      end

      it 'skips dispatch if integration provider is not webhook (e.g. slack)' do
        webhook_integration.update!(provider: :slack)
        expect(HTTParty).not_to receive(:post)

        worker.perform(account.id, delivery.id, 1)
        expect(delivery.reload).to be_pending
      end

      it 'guards against duplicate dispatch if delivery is already marked successful' do
        delivery.update!(status: :successful)
        expect(HTTParty).not_to receive(:post)

        worker.perform(account.id, delivery.id, 1)
        expect(delivery.attempts.count).to eq(0)
      end
    end

    describe 'SSRF & Internal Network Protection via Security::UrlValidator' do
      [
        'http://127.0.0.1/api/webhook',
        'http://localhost:3000/hook',
        'http://10.0.0.1/admin/callback',
        'http://192.168.1.1/router/reboot',
        'http://172.16.0.5/api',
        'http://169.254.169.254/latest/meta-data/iam/security-credentials/',
        'https://metadata.internal/webhook'
      ].each do |insecure_target_url|
        it "blocks SSRF dispatch to #{insecure_target_url} and immediately marks delivery failed" do
          delivery.update!(endpoint_url: insecure_target_url)
          expect(HTTParty).not_to receive(:post)

          expect {
            worker.perform(account.id, delivery.id, 1)
          }.to change(Webhook::DeliveryAttempt, :count).by(1)

          delivery.reload
          expect(delivery).to be_failed
          attempt = delivery.attempts.last
          expect(attempt.attempt_number).to eq(3)
          expect(attempt.error_trace).to match(/Blocked delivery to insecure or internal URL/i)
        end
      end
    end

    describe 'Network Exceptions, Timeouts, and Error Traces' do
      it 'catches Net::OpenTimeout, records error attempt, and schedules retry with backoff' do
        allow(HTTParty).to receive(:post).and_raise(Net::OpenTimeout.new('execution expired'))

        expect(Integrations::Webhooks::BroadcasterWorker).to receive(:perform_in).with(
          10.minutes,
          account.id,
          delivery.id,
          2
        )

        worker.perform(account.id, delivery.id, 1)

        delivery.reload
        expect(delivery).to be_pending
        attempt = delivery.attempts.last
        expect(attempt.error_trace).to include('execution expired')
        expect(attempt.attempt_number).to eq(1)
      end

      it 'catches Errno::ECONNREFUSED, records error attempt, and schedules retry for attempt 2' do
        allow(HTTParty).to receive(:post).and_raise(Errno::ECONNREFUSED.new('Connection refused - connect(2)'))

        expect(Integrations::Webhooks::BroadcasterWorker).to receive(:perform_in).with(
          20.minutes,
          account.id,
          delivery.id,
          3
        )

        worker.perform(account.id, delivery.id, 2)

        delivery.reload
        expect(delivery).to be_pending
        attempt = delivery.attempts.last
        expect(attempt.error_trace).to include('Connection refused')
        expect(attempt.attempt_number).to eq(2)
      end

      it 'marks delivery as failed and does not schedule retry on attempt 3 failure' do
        allow(HTTParty).to receive(:post).and_raise(SocketError.new('getaddrinfo: nodename nor servname provided, or not known'))

        expect(Integrations::Webhooks::BroadcasterWorker).not_to receive(:perform_in)

        worker.perform(account.id, delivery.id, 3)

        delivery.reload
        expect(delivery).to be_failed
        attempt = delivery.attempts.last
        expect(attempt.error_trace).to include('getaddrinfo')
        expect(attempt.attempt_number).to eq(3)
      end

      it 'truncates oversized HTTP response bodies (> 1000 characters) when storing delivery attempt' do
        oversized_body = 'X' * 5000
        allow(HTTParty).to receive(:post).and_return(
          double('Response', success?: false, code: 502, body: oversized_body)
        )

        worker.perform(account.id, delivery.id, 1)

        attempt = delivery.attempts.last
        expect(attempt.response_body.length).to be <= 1003 # 1000 + '...'
        expect(attempt.http_status).to eq(502)
        expect(attempt.error_trace).to eq('Completed with HTTP 502')
      end
    end
  end

  describe 'Integrations::Webhooks::DeliveryRetryWorker Multi-Shard Sweeper Edge Cases' do
    let(:retry_worker) { Integrations::Webhooks::DeliveryRetryWorker.new }

    it 'correctly calculates next attempt number based on existing attempts count' do
      create(:webhook_delivery_attempt, delivery: delivery, attempt_number: 1)
      create(:webhook_delivery_attempt, delivery: delivery, attempt_number: 2)

      expect(Integrations::Webhooks::BroadcasterWorker).to receive(:perform_async).with(
        account.id,
        delivery.id,
        3
      )

      retry_worker.perform(account.id, delivery.id)
    end

    it 'routes Slack integrations to NotifierWorker and Webhook integrations to BroadcasterWorker on retry' do
      slack_integration = create(:integration, account: account, provider: :slack, status: :active)
      slack_delivery = create(:webhook_delivery,
        account: account,
        resource: slack_integration,
        event_name: 'message.created',
        status: :pending
      )

      expect(Integrations::Slack::NotifierWorker).to receive(:perform_async).with(
        account.id,
        slack_delivery.id,
        1
      )

      retry_worker.perform(account.id, slack_delivery.id)
    end

    it 'sweeps orphaned deliveries across database shards' do
      account_shard1 = create(:account, shard_key: 'de')
      account_shard2 = create(:account, shard_key: 'de')

      delivery1 = create(:webhook_delivery,
        account: account_shard1,
        resource: webhook_integration,
        event_name: 'test.event',
        status: :pending,
        created_at: 2.hours.ago
      )

      integration_shard2 = create(:integration, account: account_shard2, provider: :webhook, status: :active)
      delivery2 = create(:webhook_delivery,
        account: account_shard2,
        resource: integration_shard2,
        event_name: 'test.event',
        status: :pending,
        created_at: 3.hours.ago
      )

      allow_any_instance_of(Integrations::Webhooks::DeliveryRetryWorker).to receive(:fetch_active_delivery_ids).and_return(Set.new)

      expect(Integrations::Webhooks::BroadcasterWorker).to receive(:perform_async).with(account_shard1.id, delivery1.id, 1)
      expect(Integrations::Webhooks::BroadcasterWorker).to receive(:perform_async).with(account_shard2.id, delivery2.id, 1)

      retry_worker.perform
    end
  end
end
