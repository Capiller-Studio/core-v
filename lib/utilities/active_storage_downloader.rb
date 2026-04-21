# frozen_string_literal: true

module Utilities
  class ActiveStorageDownloader
    def self.attach(record:, attachment_name:, url:)
      return unless url.present?
      return if record.send(attachment_name).attached?

      begin
        tempfile = Down.download(url)
        
        record.send(attachment_name).attach(
          io: tempfile,
          filename: tempfile.original_filename || "downloaded-file",
          content_type: tempfile.content_type
        )
      rescue Down::Error => e
        Rails.logger.error("ActiveStorageDownloader failed for #{record.class}##{record.id}: #{e.message}")
        nil
      end
    end
  end
end
