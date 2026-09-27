# frozen_string_literal: true

module Channels
  class MessageFormatter
    def self.format_for_whatsapp_and_facebook(html_content)
      return html_content unless html_content.to_s.include?("<")

      doc = Nokogiri::HTML::DocumentFragment.parse(html_content)
      
      convert_node = ->(node) {
        text = ""
        node.children.each do |child|
          if child.text?
            text += child.text
          elsif child.name == "br"
            text += "\n"
          elsif child.name == "p" || child.name == "div"
            inner = convert_node.call(child)
            text += "#{inner}\n\n"
          elsif child.name == "b" || child.name == "strong"
            text += "*#{convert_node.call(child)}*"
          elsif child.name == "i" || child.name == "em"
            text += "_#{convert_node.call(child)}_"
          elsif child.name == "s" || child.name == "del" || child.name == "strike"
            text += "~#{convert_node.call(child)}~"
          elsif child.name == "code"
            text += "```#{convert_node.call(child)}```"
          elsif child.name == "ul" || child.name == "ol"
            text += "#{convert_node.call(child)}\n"
          elsif child.name == "li"
            text += "- #{convert_node.call(child)}\n"
          else
            text += convert_node.call(child)
          end
        end
        text
      }
      
      convert_node.call(doc).strip.gsub(/\n{3,}/, "\n\n")
    end

    def self.format_for_sms(html_content)
      return html_content unless html_content.to_s.include?("<")
      
      doc = Nokogiri::HTML::DocumentFragment.parse(html_content)
      
      convert_node = ->(node) {
        text = ""
        node.children.each do |child|
          if child.text?
            text += child.text
          elsif child.name == "br" || child.name == "p" || child.name == "div" || child.name == "li"
            text += "#{convert_node.call(child)}\n"
          else
            text += convert_node.call(child)
          end
        end
        text
      }
      
      convert_node.call(doc).strip.gsub(/\n{2,}/, "\n\n")
    end
    
    def self.parse_whatsapp_markdown_to_html(markdown)
      return markdown if markdown.blank?
      
      html = markdown.dup
      
      # Bold
      html.gsub!(/\*(.*?)\*/, '<b>\1</b>')
      # Italic
      html.gsub!(/_(.*?)_/, '<i>\1</i>')
      # Strikethrough
      html.gsub!(/~(.*?)~/, '<s>\1</s>')
      # Code
      html.gsub!(/```(.*?)```/m, '<code>\1</code>')
      # Newlines
      html.gsub!(/\n/, '<br>')
      
      html
    end
    
    def self.parse_ai_markdown_to_html(markdown)
      return markdown if markdown.blank?
      
      html = markdown.dup
      
      # Github Flavored Markdown usually returned by OpenAI
      html.gsub!(/\*\*(.*?)\*\*/m, '<b>\1</b>')
      html.gsub!(/__(.*?)__/m, '<b>\1</b>')
      html.gsub!(/```(.*?)```/m, '<pre><code>\1</code></pre>')
      html.gsub!(/`([^`]+)`/, '<code>\1</code>')
      # Links [text](url)
      html.gsub!(/\[([^\]]+)\]\(([^)]+)\)/, '<a href="\2" target="_blank" rel="noopener noreferrer">\1</a>')
      html.gsub!(/\n/, '<br>')
      
      html
    end
  end
end
