require 'rails_helper'

RSpec.describe Attachment, type: :model do
  subject(:attachment) { build(:attachment) }

  describe 'Associations' do
    it { is_expected.to belong_to(:resource) }
    it { is_expected.to belong_to(:account) }
  end

  describe 'Enums' do
    it { expect(attachment).to define_enum_for(:attachment_type).with_values(
      image: 0, file: 1, video: 2, audio: 3, location: 4, fallback: 5,
      share: 6, story_mention: 7, contact: 8
    ) }
  end

  describe 'Validations' do
    context 'when resource is an EmailTemplate' do
      let(:account) { create(:account) }
      let(:template) { create(:email_template, account: account) }
      let(:attachment) { build(:attachment, resource: template, account: account) }

      it 'validates file size' do
        # We can stub byte_size to be larger than 2MB
        allow_any_instance_of(ActiveStorage::Blob).to receive(:byte_size).and_return(3.megabytes)
        # Using a valid file format first
        attachment.file.attach(io: StringIO.new('dummy'), filename: 'dummy.png', content_type: 'image/png')
        
        expect(attachment).not_to be_valid
        expect(attachment.errors[:file]).to include(I18n.t("errors.attachments.file_too_large", max_size: "2 MB"))
      end

      it 'validates content type' do
        attachment.file.attach(io: StringIO.new('dummy'), filename: 'dummy.txt', content_type: 'text/plain')
        
        expect(attachment).not_to be_valid
        expect(attachment.errors[:file]).to include(I18n.t("errors.attachments.invalid_content_type"))
      end
    end
  end

  describe 'Methods' do
    let(:account) { create(:account) }
    let(:attachment) { create(:attachment, account: account) }

    describe '#direct_download_url' do
      it 'returns nil if no file attached' do
        expect(attachment.direct_download_url).to be_nil
      end

      it 'returns url if file is attached' do
        attachment.file.attach(io: StringIO.new('dummy'), filename: 'dummy.png', content_type: 'image/png')
        expect(attachment.direct_download_url).to be_present
      end
    end

    describe '#referenced_in_published_content?' do
      it 'returns false if not email resource' do
        expect(attachment.referenced_in_published_content?).to be false
      end

      it 'returns false if no file attached' do
        template = create(:email_template, account: account)
        attachment = build(:attachment, resource: template, account: account)
        expect(attachment.referenced_in_published_content?).to be false
      end
    end
  end
end
