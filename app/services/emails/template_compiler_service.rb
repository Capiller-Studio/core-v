# frozen_string_literal: true

module Emails
  # Compiles MJML markup to email-safe HTML using the mrml gem (Rust-based).
  # Zero external dependencies — no Node.js binary required.
  #
  # Used by:
  #   - EmailTemplate#publish! (compile user-edited MJML at publish-time)
  #   - EmailTemplateLayout#publish! (compile layout MJML)
  #   - rake mjml:compile (pre-compile system mailer .mjml views)
  class TemplateCompilerService
    class CompilationError < StandardError; end

    # Compile MJML source to HTML.
    # Returns empty string for blank input; raises on invalid MJML if strict: true.
    def self.compile(mjml_content, strict: false)
      return "" if mjml_content.blank?

      require "mrml"
      result = MRML.to_html(mjml_content)
      result.presence || ""
    rescue StandardError => e
      Rails.logger.error("[TemplateCompilerService] MJML compilation failed: #{e.message}")

      raise CompilationError, "Failed to compile MJML: #{e.message}" if strict

      ""
    end

    # Compile a template body, optionally wrapping it in a layout.
    # Used when publishing a template that has an associated layout.
    def self.compile_with_layout(template_body, layout_body: nil)
      return compile(template_body) if layout_body.blank?

      # Extract content inside <mj-body>...</mj-body> from the template
      inner_content = template_body.match(/<mj-body[^>]*>(.*)<\/mj-body>/im)&.captures&.first
      inner_content ||= template_body

      # Inject template content into the layout placeholder
      final_mjml = layout_body.gsub("[[CONTENT_FOR_LAYOUT]]", inner_content)
      compile(final_mjml)
    end
  end
end
