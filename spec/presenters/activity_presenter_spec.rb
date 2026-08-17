# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ActivityPresenter do
  let(:account) { create(:account) }
  let(:user) { create(:user) }

  describe '#humanized_changes' do
    context 'when attribute is an enum' do
      let(:conversation) { create(:conversation, account: account, status: :active) }
      let(:activity) do
        create(
          :activity,
          account: account,
          actor: user,
          trackable: conversation,
          event_key: 'conversation.updated',
          object_changes: { 'status' => [0, 3] } # active (0) -> resolved (3)
        )
      end

      it 'humanizes enum changes' do
        presenter = described_class.new(activity)
        changes = presenter.humanized_changes

        expect(changes.first).to include('Status')
        expect(changes.first).to include('Active')
        expect(changes.first).to include('Resolved')
      end
    end

    context 'when attribute is a translation' do
      let(:activity) do
        create(
          :activity,
          account: account,
          actor: user,
          event_key: 'conversation.updated',
          object_changes: { 'translation_es' => ['Hola', 'Adios'] }
        )
      end

      it 'formats translation updates' do
        presenter = described_class.new(activity)
        changes = presenter.humanized_changes

        expect(changes.first).to include('ES')
      end
    end

    context 'when attribute is a standard field' do
      let(:activity) do
        create(
          :activity,
          account: account,
          actor: user,
          event_key: 'conversation.updated',
          object_changes: { 'name' => ['Old Name', 'New Name'] }
        )
      end

      it 'formats standard attribute update' do
        presenter = described_class.new(activity)
        changes = presenter.humanized_changes

        expect(changes.first).to include('Name')
      end
    end

    context 'when object_changes is empty' do
      let(:activity) do
        create(
          :activity,
          account: account,
          actor: user,
          event_key: 'custom_event',
          object_changes: {}
        )
      end

      it 'falls back to translated description' do
        presenter = described_class.new(activity)
        changes = presenter.humanized_changes

        expect(changes).to eq([activity.translated_description])
      end
    end
  end
end
