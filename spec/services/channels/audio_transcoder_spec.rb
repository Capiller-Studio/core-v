# frozen_string_literal: true

require "rails_helper"

RSpec.describe Channels::AudioTranscoder do
  describe ".audio_attachment?" do
    it "returns true if attachment responds to audio? and is true" do
      att = double("Attachment", audio?: true)
      expect(described_class.audio_attachment?(att)).to be true
    end

    it "returns true if attachment_type is 'audio'" do
      att = double("Attachment", audio?: false, attachment_type: "audio")
      expect(described_class.audio_attachment?(att)).to be true
    end

    it "returns false if attachment is a file even with audio content_type" do
      blob = double("Blob", content_type: "audio/webm", filename: "recording.bin")
      file = double("File", attached?: true, blob: blob)
      att = double("Attachment", audio?: false, attachment_type: "file", file: file)
      expect(described_class.audio_attachment?(att)).to be false
    end

    it "returns false for image files" do
      blob = double("Blob", content_type: "image/png", filename: "photo.png")
      file = double("File", attached?: true, blob: blob)
      att = double("Attachment", audio?: false, attachment_type: "image", file: file)
      expect(described_class.audio_attachment?(att)).to be false
    end
  end

  describe ".ensure_compatible_audio_url" do
    let(:direct_url) { "https://cdn.deskbolic.app/attachments/audio.wav" }

    context "when attachment is not audio" do
      let(:att) { double("Attachment", audio?: false, attachment_type: "image", direct_download_url: direct_url) }

      it "returns direct_download_url without checking transcoding" do
        expect(described_class.ensure_compatible_audio_url(att, channel_type: :instagram)).to eq(direct_url)
      end
    end

    context "with WAV audio on Instagram" do
      let(:blob) { double("Blob", content_type: "audio/wav", filename: "voice.wav") }
      let(:file) { double("File", attached?: true, blob: blob) }
      let(:att) { double("Attachment", audio?: true, attachment_type: "audio", file: file, direct_download_url: direct_url) }

      it "returns direct_download_url directly because Instagram supports WAV" do
        expect(described_class).not_to receive(:transcode_to_m4a)
        expect(described_class.ensure_compatible_audio_url(att, channel_type: :instagram)).to eq(direct_url)
      end
    end

    context "with WAV audio on Facebook Page" do
      let(:blob) { double("Blob", content_type: "audio/wav", filename: "voice.wav") }
      let(:file) { double("File", attached?: true, blob: blob) }
      let(:att) { double("Attachment", audio?: true, attachment_type: "audio", file: file, direct_download_url: direct_url) }

      it "returns direct_download_url directly because Facebook supports WAV" do
        expect(described_class).not_to receive(:transcode_to_m4a)
        expect(described_class.ensure_compatible_audio_url(att, channel_type: :facebook_page)).to eq(direct_url)
      end
    end

    context "with M4A audio on WhatsApp" do
      let(:blob) { double("Blob", content_type: "audio/mp4", filename: "voice.m4a") }
      let(:file) { double("File", attached?: true, blob: blob) }
      let(:att) { double("Attachment", audio?: true, attachment_type: "audio", file: file, direct_download_url: direct_url) }

      it "returns direct_download_url directly because WhatsApp supports M4A" do
        expect(described_class).not_to receive(:transcode_to_m4a)
        expect(described_class.ensure_compatible_audio_url(att, channel_type: :whatsapp)).to eq(direct_url)
      end
    end

    context "with WebM audio when ffmpeg is not installed" do
      let(:blob) { double("Blob", content_type: "audio/webm", filename: "voice.webm") }
      let(:file) { double("File", attached?: true, blob: blob) }
      let(:att) { double("Attachment", audio?: true, attachment_type: "audio", file: file, direct_download_url: direct_url) }

      before do
        allow(described_class).to receive(:ffmpeg_installed?).and_return(false)
      end

      it "safely returns direct_download_url without crashing" do
        expect(described_class.ensure_compatible_audio_url(att, channel_type: :instagram)).to eq(direct_url)
      end
    end

    context "with WebM audio when ffmpeg is installed" do
      let(:blob) { double("Blob", content_type: "audio/webm", filename: "recording.webm") }
      let(:file) { double("File", attached?: true, blob: blob, download: "fake-audio-bytes") }
      let(:transcoded_url) { "https://cdn.deskbolic.app/attachments/recording.m4a" }
      let(:att) { double("Attachment", audio?: true, attachment_type: "audio", file: file, direct_download_url: direct_url) }

      before do
        allow(described_class).to receive(:ffmpeg_installed?).and_return(true)
      end

      it "transcodes to m4a and attaches the converted file" do
        status_double = double("ProcessStatus", success?: true)
        allow(Open3).to receive(:capture3).and_return(["", "", status_double])
        allow(File).to receive(:size?).and_return(1024)

        expect(file).to receive(:attach).with(hash_including(filename: "recording.m4a", content_type: "audio/mp4"))
        expect(att).to receive(:reload)
        allow(att).to receive(:direct_download_url).and_return(transcoded_url)

        expect(described_class.ensure_compatible_audio_url(att, channel_type: :instagram)).to eq(transcoded_url)
      end

      it "falls back to direct_download_url if ffmpeg command fails" do
        status_double = double("ProcessStatus", success?: false)
        allow(Open3).to receive(:capture3).and_return(["", "error transcoding", status_double])

        expect(Rails.logger).to receive(:warn).with(/Transcoding failed/)
        expect(described_class.ensure_compatible_audio_url(att, channel_type: :instagram)).to eq(direct_url)
      end

      it "rescues unexpected errors and returns direct_download_url" do
        allow(file).to receive(:download).and_raise(StandardError.new("S3 network error"))

        expect(Rails.logger).to receive(:warn).with(/Error during audio transcoding: S3 network error/)
        expect(described_class.ensure_compatible_audio_url(att, channel_type: :instagram)).to eq(direct_url)
      end
    end

    context "with OGG audio" do
      let(:blob) { double("Blob", content_type: "audio/ogg", filename: "voice.ogg") }
      let(:file) { double("File", attached?: true, blob: blob) }
      let(:att) { double("Attachment", audio?: true, attachment_type: "audio", file: file, direct_download_url: direct_url) }

      it "is natively supported on WhatsApp without transcoding" do
        expect(described_class).not_to receive(:transcode_to_m4a)
        expect(described_class.ensure_compatible_audio_url(att, channel_type: :whatsapp)).to eq(direct_url)
      end

      it "triggers transcoding on Instagram when ffmpeg is installed" do
        allow(described_class).to receive(:ffmpeg_installed?).and_return(true)
        expect(described_class).to receive(:transcode_to_m4a).with(att).and_return("https://cdn.deskbolic.app/attachments/transcoded.m4a")
        expect(described_class.ensure_compatible_audio_url(att, channel_type: :instagram)).to eq("https://cdn.deskbolic.app/attachments/transcoded.m4a")
      end
    end

    context "with MP3 audio" do
      let(:blob) { double("Blob", content_type: "audio/mpeg", filename: "voice.mp3") }
      let(:file) { double("File", attached?: true, blob: blob) }
      let(:att) { double("Attachment", audio?: true, attachment_type: "audio", file: file, direct_download_url: direct_url) }

      it "is natively supported on Facebook Page without transcoding" do
        expect(described_class).not_to receive(:transcode_to_m4a)
        expect(described_class.ensure_compatible_audio_url(att, channel_type: :facebook_page)).to eq(direct_url)
      end

      it "is natively supported on WhatsApp without transcoding" do
        expect(described_class).not_to receive(:transcode_to_m4a)
        expect(described_class.ensure_compatible_audio_url(att, channel_type: :whatsapp)).to eq(direct_url)
      end
    end
  end
end
