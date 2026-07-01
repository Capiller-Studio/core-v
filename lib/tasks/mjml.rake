# frozen_string_literal: true

namespace :mjml do
  desc "Compile .mjml mailer source files to .html.erb views using mrml (Rust)"
  task compile: :environment do
    require "mrml"

    compiled = 0
    skipped = 0
    errors = 0

    # Scan both core engine and the host app for mailer sources.
    # - Core engine: shared mailer views (e.g., conversation replies)
    # - Host app: app-specific mailer views
    source_roots = []
    source_roots << [Core::Engine.root.join("app/views/mailer_sources"), Core::Engine.root.join("app/views")]
    source_roots << [Rails.root.join("app/views/mailer_sources"), Rails.root.join("app/views")]

    source_roots.each do |source_dir, output_dir|
      next unless source_dir.exist?

      label = source_dir.to_s.include?("core") ? "core" : File.basename(Rails.root)
      puts "\nScanning #{label}: #{source_dir}"

      Dir.glob(source_dir.join("**/*.mjml")).each do |source_path|
        # Skip partials
        next if File.basename(source_path).start_with?("_")

        relative = Pathname.new(source_path).relative_path_from(source_dir)
        output_path = output_dir.join(relative.sub_ext(".html.erb"))

        mjml_content = File.read(source_path)

        # Naive <mj-include> resolver since mrml from string doesn't support paths
        mjml_content.gsub!(/<mj-include\s+path="([^"]+)"\s*\/>/) do
          include_path = source_dir.join(File.dirname(relative), $1)
          File.read(include_path)
        end

        begin
          html = Emails::TemplateCompilerService.compile(mjml_content, strict: true)

          # Convert placeholder markers back to ERB tags:
          #   [[ERB= expr ]]   → <%= expr %>   (escaped output)
          #   [[ERB== expr ]]  → <%== expr %>  (raw/unescaped output)
          #   [[ERB- code ]]   → <% code %>    (code execution, no output)
          html.gsub!(/\[\[ERB==\s*(.*?)\s*\]\]/, '<%== \1 %>')
          html.gsub!(/\[\[ERB=\s*(.*?)\s*\]\]/, '<%= \1 %>')
          html.gsub!(/\[\[ERB-\s*(.*?)\s*\]\]/, '<% \1 %>')

          # Skip if output already exists and is identical
          if output_path.exist? && File.read(output_path) == html
            skipped += 1
            next
          end

          FileUtils.mkdir_p(File.dirname(output_path))
          File.write(output_path, html)
          compiled += 1
          puts "  ✓ #{relative} → #{relative.sub_ext('.html.erb')}"
        rescue Emails::TemplateCompilerService::CompilationError, StandardError => e
          errors += 1
          puts "  ✗ #{relative}: #{e.message}"
        end
      end
    end

    puts "\nMJML compilation complete: #{compiled} compiled, #{skipped} unchanged, #{errors} errors"
  end
end
