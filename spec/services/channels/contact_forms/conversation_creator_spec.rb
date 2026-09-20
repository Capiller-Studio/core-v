# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Channels::ContactForms::ConversationCreator, type: :service do
  let(:account) { create(:account) }
  let(:channel) do
    create(
      :channel_contact_form,
      account: account,
      send_confirmation_email: true,
      allow_attachments: true
    )
  end
  let!(:inbox) { create(:inbox, channel: channel, account: account, primary_inbox: true) }

  let(:uploaded_image) do
    Rack::Test::UploadedFile.new(
      StringIO.new('dummy-image'),
      'image/png',
      original_filename: 'receipt.png'
    )
  end

  around do |example|
    account.with_shard do
      example.run
    end
  end

  before do
    # Create standard custom fields
    Accounts::DefaultCustomFieldsCreator.call(account: account)

    # Associate default custom fields with this contact form
    account.custom_fields.each_with_index do |cf, idx|
      create(:custom_field_resource, custom_field: cf, resource: channel, configurations: { position: idx })
    end
  end

  describe '#call' do
    let(:form_params) do
      {
        'name' => 'Alice Johnson',
        'email' => 'alice@example.com',
        'subject' => 'Need billing support',
        'message' => 'Please update my billing method to company card.',
        'priority' => 'high'
      }
    end

    it 'creates a real Customer, Conversation, ConversationMember, and Message in shard database' do
      expect {
        conversation = described_class.call(
          contact_form_channel: channel,
          form_params: form_params
        )

        expect(conversation).to be_persisted
        expect(conversation.account).to eq(account)
        expect(conversation.inbox).to eq(inbox)
        expect(conversation.title).to eq('Need billing support')
        expect(conversation.priority).to eq('high')
        expect(conversation.source).to eq('help_center')

        # Customer assertions
        customer = conversation.customers.first
        expect(customer).to be_present
        expect(customer.name).to eq('Alice Johnson')
        expect(customer.email).to eq('alice@example.com')

        # CustomerInbox association
        expect(CustomerInbox.find_by(customer: customer, inbox: inbox)).to be_present

        # ConversationMember association
        expect(conversation.conversation_members.where(member: customer).exists?).to be(true)

        # Message assertions
        message = conversation.messages.first
        expect(message).to be_present
        expect(message.sender).to eq(customer)
        expect(message.content).to eq('Please update my billing method to company card.')
        expect(message.source).to eq('help_center')
        expect(message.incoming?).to be(true)
      }.to change(Conversation, :count).by(1)
       .and change(Customer, :count).by(1)
       .and change(Message, :count).by(1)
    end

    it 'maps unmapped custom fields to jsonb data columns for customer and conversation' do
      cf_membership = create(
        :custom_field,
        account: account,
        key: 'membership_tier',
        entity_type: :customer,
        field_type: :text,
        mapped_to: nil
      )
      create(:custom_field_resource, custom_field: cf_membership, resource: channel)

      cf_incident = create(
        :custom_field,
        account: account,
        key: 'incident_id',
        entity_type: :conversation,
        field_type: :text,
        mapped_to: nil
      )
      create(:custom_field_resource, custom_field: cf_incident, resource: channel)

      extended_params = form_params.merge(
        'membership_tier' => 'Platinum',
        'incident_id' => 'INC-9988'
      )

      conversation = described_class.call(
        contact_form_channel: channel,
        form_params: extended_params
      )

      customer = conversation.customers.first
      expect(customer.data['membership_tier']).to eq('Platinum')
      expect(conversation.data['incident_id']).to eq('INC-9988')
    end

    it 'deduplicates existing customer by email without creating a new record' do
      existing_customer = create(
        :customer,
        account: account,
        email: 'alice@example.com',
        name: 'Alice Original'
      )

      expect {
        conversation = described_class.call(
          contact_form_channel: channel,
          form_params: form_params
        )

        expect(conversation.customers.first.id).to eq(existing_customer.id)
      }.not_to change(Customer, :count)
    end

    it 'handles anonymous submission with no email provided' do
      anon_params = {
        'name' => 'Anonymous User',
        'subject' => 'Anonymous feedback',
        'message' => 'Great product!'
      }

      conversation = nil
      expect {
        conversation = described_class.call(
          contact_form_channel: channel,
          form_params: anon_params
        )
      }.to change(Conversation, :count).by(1)
       .and change(Customer, :count).by(1)

      expect(conversation).to be_persisted
      customer = conversation.customers.first
      expect(customer.email).to be_nil
      expect(customer.external_id).to match(/\Aanon-[0-9a-f\-]{36}\z/)
    end

    it 'associates customer with explicit identifier parameter when provided' do
      conversation = described_class.call(
        contact_form_channel: channel,
        form_params: form_params,
        identifier: 'ext_user_98765'
      )

      customer = conversation.customers.first
      expect(customer.external_id).to eq('ext_user_98765')
    end

    it 'generates distinct unique external_ids for successive anonymous submissions' do
      anon_params = {
        'name' => 'Anonymous User',
        'subject' => 'Anonymous feedback',
        'message' => 'Great product!'
      }

      conv1 = described_class.call(contact_form_channel: channel, form_params: anon_params)
      conv2 = described_class.call(contact_form_channel: channel, form_params: anon_params)

      cust1 = conv1.customers.first
      cust2 = conv2.customers.first

      expect(cust1.id).not_to eq(cust2.id)
      expect(cust1.external_id).to match(/\Aanon-[0-9a-f\-]{36}\z/)
      expect(cust2.external_id).to match(/\Aanon-[0-9a-f\-]{36}\z/)
      expect(cust1.external_id).not_to eq(cust2.external_id)
    end

    it 'enqueues confirmation email when send_confirmation_email is enabled' do
      expect {
        described_class.call(
          contact_form_channel: channel,
          form_params: form_params
        )
      }.to have_enqueued_mail(ContactFormMailer, :confirmation_email)
    end

    it 'does not enqueue confirmation email when send_confirmation_email is disabled' do
      channel.update!(send_confirmation_email: false)

      expect {
        described_class.call(
          contact_form_channel: channel,
          form_params: form_params
        )
      }.not_to have_enqueued_mail(ContactFormMailer, :confirmation_email)
    end

    it 'persists attached files on the created message' do
      conversation = described_class.call(
        contact_form_channel: channel,
        form_params: form_params,
        attachments: [uploaded_image]
      )

      message = conversation.messages.first
      expect(message.attachments.count).to eq(1)
      expect(message.attachments.first.file).to be_attached
      expect(message.attachments.first.file.filename.to_s).to eq('receipt.png')
    end

    it 'resiliently resolves inbox to channel.inboxes.first when primary_inbox flag is not set' do
      inbox.update!(primary_inbox: false)
      expect(channel.reload.primary_inbox).to be_nil

      conversation = described_class.call(
        contact_form_channel: channel,
        form_params: form_params
      )

      expect(conversation).to be_persisted
      expect(conversation.inbox).to eq(inbox)
    end

    it 'returns nil gracefully when contact form channel has no inboxes' do
      inbox.destroy!

      expect {
        result = described_class.call(
          contact_form_channel: channel,
          form_params: form_params
        )
        expect(result).to be_nil
      }.not_to raise_error
    end
  end
end
