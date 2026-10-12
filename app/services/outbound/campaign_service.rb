# frozen_string_literal: true

require "csv"

module Outbound
  class CampaignService < ApplicationService
    # Send a single personalized outreach email
    # Usage in rails c:
    #   Outbound::CampaignService.send_email(to: "lead@startup.com", name: "Alex", company: "Acme", competitor: "intercom")
    def self.send_email(to:, name: nil, company: nil, competitor: nil, custom_hook: nil, dry_run: false)
      new.send_email(to: to, name: name, company: company, competitor: competitor, custom_hook: custom_hook, dry_run: dry_run)
    end

    # Send a batch of leads
    # Usage in rails c:
    #   leads = [
    #     { email: "alex@acme.com", name: "Alex", company: "Acme", competitor: "intercom" },
    #     { email: "sarah@beta.io", name: "Sarah", company: "Beta", competitor: "zendesk" }
    #   ]
    #   Outbound::CampaignService.send_batch(leads, delay_seconds: 3, dry_run: true)
    def self.send_batch(leads, delay_seconds: 3, dry_run: false)
      new.send_batch(leads, delay_seconds: delay_seconds, dry_run: dry_run)
    end

    # Send leads loaded directly from a CSV file
    # Usage in rails c:
    #   Outbound::CampaignService.send_from_csv("leads.csv", delay_seconds: 3, dry_run: true)
    def self.send_from_csv(file_path, delay_seconds: 3, dry_run: false)
      new.send_from_csv(file_path, delay_seconds: delay_seconds, dry_run: dry_run)
    end

    # Preview email content without sending
    # Usage in rails c:
    #   preview = Outbound::CampaignService.preview(to: "alex@acme.com", name: "Alex", company: "Acme")
    def self.preview(to:, name: nil, company: nil, competitor: nil, custom_hook: nil)
      new.preview(to: to, name: name, company: company, competitor: competitor, custom_hook: custom_hook)
    end

    def send_email(to:, name: nil, company: nil, competitor: nil, custom_hook: nil, dry_run: false)
      email = to.to_s.strip
      unless valid_email?(email)
        return { success: false, error: "Invalid email format: #{email.inspect}" }
      end

      mail = OutreachMailer.outreach(
        to: email,
        name: name,
        company: company,
        competitor: competitor,
        custom_hook: custom_hook
      )

      if dry_run
        puts " [DRY RUN] Would send to: #{email} | Name: #{name.inspect} | Company: #{company.inspect} | Subject: #{mail.subject}"
        return { success: true, dry_run: true, to: email, subject: mail.subject }
      end

      mail.deliver_now
      puts " [SENT] Successfully sent outreach to #{email} (Subject: #{mail.subject})"
      { success: true, to: email, subject: mail.subject }
    rescue StandardError => e
      puts "❌ [FAILED] Could not send to #{email}: #{e.message}"
      { success: false, to: email, error: e.message }
    end

    def send_batch(leads, delay_seconds: 3, dry_run: false)
      leads = Array(leads)
      total = leads.size
      sent = 0
      skipped = 0
      errors = []
      seen_emails = Set.new

      puts "\n" + ("=" * 60)
      puts "🚀 Starting Deskbolic Founder Outreach #{dry_run ? '[DRY RUN] ' : ''}Campaign (#{total} leads)"
      puts "From: Ahsan from Deskbolic <ahsan@techbolic.com>"
      puts "Delay between emails: #{delay_seconds} seconds"
      puts ("=" * 60) + "\n"

      leads.each_with_index do |lead, idx|
        lead = lead.with_indifferent_access if lead.respond_to?(:with_indifferent_access)
        email = (lead[:email] || lead[:to]).to_s.strip

        if email.blank? || !valid_email?(email)
          puts "⚠️  [SKIPPED #{idx + 1}/#{total}] Invalid email: #{email.inspect}"
          skipped += 1
          next
        end

        normalized_email = email.downcase
        if seen_emails.include?(normalized_email)
          puts "⚠️  [SKIPPED #{idx + 1}/#{total}] Duplicate in batch: #{email}"
          skipped += 1
          next
        end
        seen_emails.add(normalized_email)

        name = lead[:name] || lead[:first_name]
        company = lead[:company] || lead[:organization]
        competitor = lead[:competitor]
        custom_hook = lead[:custom_hook] || lead[:hook]

        print("[#{idx + 1}/#{total}] #{email}... ")
        result = send_email(
          to: email,
          name: name,
          company: company,
          competitor: competitor,
          custom_hook: custom_hook,
          dry_run: dry_run
        )

        if result[:success]
          sent += 1
        else
          errors << { email: email, error: result[:error] }
        end

        # Sleep between emails if not dry run and not the last email
        if !dry_run && delay_seconds.to_i.positive? && idx < total - 1
          sleep(delay_seconds.to_f)
        end
      end

      puts "\n" + ("=" * 60)
      puts "✅ Outreach #{dry_run ? '[DRY RUN] ' : ''}Complete: #{sent} sent, #{skipped} skipped, #{errors.size} errors out of #{total} total."
      puts ("=" * 60) + "\n"

      {
        total: total,
        sent: sent,
        skipped: skipped,
        errors: errors,
        dry_run: dry_run
      }
    end

    def send_from_csv(file_path, delay_seconds: 3, dry_run: false)
      unless File.exist?(file_path)
        raise(ArgumentError, "CSV file not found at path: #{file_path}")
      end

      leads = []
      CSV.foreach(file_path, headers: true) do |row|
        data = row.to_h.transform_keys { |k| k.to_s.downcase.strip.to_sym }
        leads << {
          email: data[:email] || data[:mail] || data[:to],
          name: data[:name] || data[:first_name] || data[:contact_name],
          company: data[:company] || data[:organization] || data[:account],
          competitor: data[:competitor] || data[:current_tool] || data[:alternative_to],
          custom_hook: data[:custom_hook] || data[:hook] || data[:note]
        }
      end

      send_batch(leads, delay_seconds: delay_seconds, dry_run: dry_run)
    end

    def preview(to:, name: nil, company: nil, competitor: nil, custom_hook: nil)
      mail = OutreachMailer.outreach(
        to: to,
        name: name,
        company: company,
        competitor: competitor,
        custom_hook: custom_hook
      )

      {
        subject: mail.subject,
        from: mail.from,
        reply_to: mail.reply_to,
        to: mail.to,
        html_part: mail.html_part&.body&.to_s,
        text_part: mail.text_part&.body&.to_s
      }
    end

    private

    def valid_email?(email)
      return false if email.blank?

      URI::MailTo::EMAIL_REGEXP.match?(email)
    end
  end
end
