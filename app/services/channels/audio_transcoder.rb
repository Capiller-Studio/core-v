# frozen_string_literal: true

require "open3"
require "tempfile"

module Channels
  class AudioTranscoder
    # Meta Instagram supported: aac, m4a, wav, mp4
    INSTAGRAM_SUPPORTED = %w[audio/aac audio/x-aac audio/m4a audio/x-m4a audio/mp4 audio/wav audio/x-wav].freeze
    # Meta WhatsApp supported: aac, mp4 (m4a), mpeg (mp3), amr, ogg (opus)
    WHATSAPP_SUPPORTED  = %w[audio/aac audio/x-aac audio/m4a audio/x-m4a audio/mp4 audio/mpeg audio/mp3 audio/amr audio/ogg].freeze
    # Meta Facebook supported: aac, m4a, mp4, mp3, wav
    FACEBOOK_SUPPORTED  = %w[audio/aac audio/x-aac audio/m4a audio/x-m4a audio/mp4 audio/mpeg audio/mp3 audio/wav audio/x-wav].freeze

    def self.ffmpeg_installed?
      system("which ffmpeg > /dev/null 2>&1")
    end

    def self.ensure_compatible_audio_url(attachment, channel_type:)
      return attachment.direct_download_url unless audio_attachment?(attachment)

      file = attachment.respond_to?(:file) ? attachment.file : nil
      blob = file.respond_to?(:blob) ? file.blob : nil
      content_type = blob&.content_type.to_s.downcase
      filename = blob&.filename.to_s.downcase

      supported_types = case channel_type.to_sym
      when :instagram then INSTAGRAM_SUPPORTED
      when :whatsapp then WHATSAPP_SUPPORTED
      when :facebook_page, :facebook then FACEBOOK_SUPPORTED
      else []
      end

      is_supported = supported_types.any? { |t| content_type.include?(t) } ||
                     filename.match?(/\.(m4a|aac|mp4)\z/) ||
                     (channel_type.to_sym != :whatsapp && filename.end_with?(".wav")) ||
                     (channel_type.to_sym != :instagram && filename.end_with?(".mp3")) ||
                     (channel_type.to_sym == :whatsapp && filename.end_with?(".ogg"))

      return attachment.direct_download_url if is_supported

      if ffmpeg_installed?
        transcode_to_m4a(attachment)
      else
        attachment.direct_download_url
      end
    end

    def self.audio_attachment?(attachment)
      (attachment.respond_to?(:audio?) && attachment.audio?) ||
        (attachment.respond_to?(:attachment_type) && attachment.attachment_type.to_s == "audio")
    end

    def self.transcode_to_m4a(attachment)
      return attachment.direct_download_url unless ffmpeg_installed?

      input_ext = File.extname(attachment.file.blob.filename.to_s).presence || ".bin"
      input_tempfile = Tempfile.new(["original_audio", input_ext])
      input_tempfile.binmode
      input_tempfile.write(attachment.file.download)
      input_tempfile.flush

      output_tempfile = Tempfile.new(["transcoded_audio", ".m4a"])
      output_tempfile.close

      cmd = [
        "ffmpeg", "-y",
        "-i", input_tempfile.path,
        "-c:a", "aac",
        "-b:a", "64k",
        "-ar", "44100",
        "-movflags", "+faststart",
        output_tempfile.path
      ]

      _stdout, stderr, status = Open3.capture3(*cmd)
      if status.success? && File.size?(output_tempfile.path).to_i > 0
        base_name = File.basename(attachment.file.blob.filename.to_s, ".*")
        File.open(output_tempfile.path, "rb") do |io|
          attachment.file.attach(
            io: io,
            filename: "#{base_name}.m4a",
            content_type: "audio/mp4"
          )
        end
        attachment.reload
        attachment.direct_download_url
      else
        Rails.logger.warn("[Channels::AudioTranscoder] Transcoding failed: #{stderr}")
        attachment.direct_download_url
      end
    rescue StandardError => e
      Rails.logger.warn("[Channels::AudioTranscoder] Error during audio transcoding: #{e.message}")
      attachment.direct_download_url
    ensure
      input_tempfile&.close!
      output_tempfile&.unlink
    end
  end
end
