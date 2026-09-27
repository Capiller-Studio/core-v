require 'rails_helper'

RSpec.describe Channels::MessageFormatter do
  describe '.format_for_whatsapp_and_facebook' do
    it 'converts html to markdown' do
      html = "Hello<br>This is <b>bold</b> and <i>italic</i> and <s>strike</s> and <code>code</code>."
      markdown = described_class.format_for_whatsapp_and_facebook(html)
      
      expect(markdown).to eq("Hello\nThis is *bold* and _italic_ and ~strike~ and ```code```.")
    end

    it 'handles lists and paragraphs' do
      html = "<p>Intro</p><ul><li>One</li><li>Two</li></ul>"
      markdown = described_class.format_for_whatsapp_and_facebook(html)
      
      expect(markdown).to eq("Intro\n\n- One\n- Two")
    end

    it 'returns original text if no html tags' do
      expect(described_class.format_for_whatsapp_and_facebook("Plain text")).to eq("Plain text")
    end
  end

  describe '.format_for_sms' do
    it 'strips tags and formats newlines' do
      html = "Hello<br>This is <b>bold</b> and <i>italic</i>.<p>Bye</p>"
      sms = described_class.format_for_sms(html)
      
      expect(sms).to eq("Hello\nThis is bold and italic.Bye")
    end

    it 'handles list items cleanly' do
      html = "<ul><li>One</li><li>Two</li></ul>"
      sms = described_class.format_for_sms(html)
      
      expect(sms).to eq("One\nTwo")
    end
  end

  describe '.parse_whatsapp_markdown_to_html' do
    it 'converts whatsapp markdown back to html' do
      markdown = "Hello\n*bold* _italic_ ~strike~ ```code```"
      html = described_class.parse_whatsapp_markdown_to_html(markdown)
      
      expect(html).to eq("Hello<br><b>bold</b> <i>italic</i> <s>strike</s> <code>code</code>")
    end

    it 'returns blank if blank' do
      expect(described_class.parse_whatsapp_markdown_to_html("")).to eq("")
    end
  end

  describe '.parse_ai_markdown_to_html' do
    it 'converts **bold**, __bold__, code blocks, inline code, and links to html' do
      markdown = "Hello!\nHere is **bold 1** and __bold 2__.\nCheck `inline code` and:\n```\nblock code\n```\nRead more at [Knowledge Base](https://helpbolic.com/kb)."
      html = described_class.parse_ai_markdown_to_html(markdown)

      expect(html).to include('<b>bold 1</b>')
      expect(html).to include('<b>bold 2</b>')
      expect(html).to include('<code>inline code</code>')
      expect(html).to include('<pre><code>')
      expect(html).to include('<a href="https://helpbolic.com/kb" target="_blank" rel="noopener noreferrer">Knowledge Base</a>')
      expect(html).to include('<br>')
    end

    it 'returns blank if input is blank' do
      expect(described_class.parse_ai_markdown_to_html('')).to eq('')
      expect(described_class.parse_ai_markdown_to_html(nil)).to be_nil
    end
  end
end
