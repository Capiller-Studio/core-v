# frozen_string_literal: true

# == Schema Information
#
# Table name: attachments
#
#  id              :uuid             not null, primary key
#  attachment_type :integer          default("image"), not null
#  extension       :string
#  latitude        :float
#  longitude       :float
#  remote_url      :string
#  resource_type   :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :uuid             not null
#  resource_id     :uuid             not null
#
# Indexes
#
#  index_attachments_on_account_id                      (account_id)
#  index_attachments_on_account_id_and_attachment_type  (account_id,attachment_type)
#  index_attachments_on_resource                        (resource_type,resource_id)
#
class Attachment < ShardRecord
  # Maximum file size for email template images (2MB)
  EMAIL_IMAGE_MAX_SIZE = 2.megabytes

  # Allowed content types for email template images
  EMAIL_IMAGE_CONTENT_TYPES = %w[
    image/jpeg
    image/png
    image/gif
    image/webp
  ].freeze

  belongs_to :resource, polymorphic: true
  belongs_to :account

  has_one_attached :file

  validate :validate_email_image_constraints, if: :email_resource?

  enum :attachment_type, { image: 0, file: 1, video: 2, audio: 3, location: 4, fallback: 5, share: 6, story_mention: 7, contact: 8 }

  def direct_download_url
    return unless file.attached?

    if ActiveStorage::Current.url_options.blank?
      ActiveStorage::Current.url_options = Rails.application.routes.default_url_options.presence || ActionMailer::Base.default_url_options
    end
    file.blob.url
  end

  # Check if this attachment's URL is referenced in any published template body/compiled_html.
  # Used to prevent deletion of images that would break live emails.
  def referenced_in_published_content?
    return false unless direct_download_url.present? && email_resource?

    url = direct_download_url
    resource.translations.any? do |t|
      t.compiled_html&.include?(url) || t.body&.include?(url)
    end
  end

  private

  def email_resource?
    resource_type.in?(%w[EmailTemplate EmailTemplateLayout])
  end

  def validate_email_image_constraints
    return unless file.attached?

    if file.blob.byte_size > EMAIL_IMAGE_MAX_SIZE
      errors.add(:file, I18n.t("errors.attachments.file_too_large", max_size: "2 MB"))
    end

    unless file.blob.content_type.in?(EMAIL_IMAGE_CONTENT_TYPES)
      errors.add(:file, I18n.t("errors.attachments.invalid_content_type"))
    end
  end
end
