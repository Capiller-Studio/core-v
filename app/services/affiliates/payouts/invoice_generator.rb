# frozen_string_literal: true

require "prawn"
require "prawn/table"

module Affiliates
  module Payouts
    class InvoiceGenerator < ApplicationService
      attr_reader :payout, :pdf, :profile, :user

      def initialize(payout:)
        @payout = payout
        @profile = payout&.profile
        @user = @profile&.user
        @pdf = Prawn::Document.new(
          margin: 36,
          page_size: "A4"
        )
      end

      def call
        return false unless payout

        build_pdf
        attach_pdf
        payout.invoice_pdf
      end

      private

      def build_pdf
        pdf.font("Helvetica")

        add_header
        add_divider
        add_meta_and_recipient
        add_divider
        add_commissions_table
        add_summary
        add_footer
      end

      def add_header
        pdf.fill_color "1E293B"
        pdf.text "Capiller Rely", size: 20, style: :bold
        pdf.fill_color "64748B"
        pdf.text "Affiliate Payout Statement & Invoice", size: 10
        pdf.move_down 10
      end

      def add_meta_and_recipient
        y_pos = pdf.cursor

        # Left Column: Affiliate Details
        pdf.bounding_box([0, y_pos], width: 260) do
          pdf.fill_color "1E293B"
          pdf.text "RECIPIENT", size: 9, style: :bold
          pdf.move_down 4

          name = user&.display_name.presence || user&.name.presence || user&.email.presence || "Affiliate"
          pdf.text name, size: 11, style: :bold
          pdf.fill_color "475569"
          pdf.text user&.email.to_s, size: 9 if user&.email.present?
          pdf.text "Referral Code: #{profile&.referral_code}", size: 9 if profile&.referral_code.present?
        end

        # Right Column: Invoice / Payout Meta
        pdf.bounding_box([280, y_pos], width: 240) do
          pdf.fill_color "1E293B"
          pdf.text "PAYOUT DETAILS", size: 9, style: :bold
          pdf.move_down 4

          pdf.fill_color "475569"
          pdf.text "Statement #: #{payout.code}", size: 9, style: :bold
          pdf.text "Date: #{payout.created_at&.strftime('%B %d, %Y') || Time.current.strftime('%B %d, %Y')}", size: 9
          pdf.text "Status: #{payout.status.to_s.titleize}", size: 9
          pdf.text "Currency: #{payout.currency}", size: 9
          if payout.external_id.present?
            pdf.text "Transfer Reference: #{payout.external_id}", size: 9
          end
        end

        pdf.move_down 15
      end

      def add_commissions_table
        commissions = Affiliate::Commission.where(id: payout.commission_ids).order(:created_at)

        table_data = [
          ["#", "Commission ID", "Date", "Description", "Currency", "Amount"]
        ]

        if commissions.any?
          commissions.each_with_index do |comm, idx|
            table_data << [
              (idx + 1).to_s,
              comm.id.to_s.first(8),
              comm.created_at.strftime("%b %d, %Y"),
              "Referral Commission (#{comm.commission_type.to_s.titleize})",
              comm.currency,
              format("%.2f", comm.amount)
            ]
          end
        else
          table_data << [
            "1",
            payout.code,
            payout.created_at&.strftime("%b %d, %Y") || Time.current.strftime("%b %d, %Y"),
            "Affiliate Earnings Payout",
            payout.currency,
            format("%.2f", payout.amount)
          ]
        end

        pdf.table(table_data, header: true, width: pdf.bounds.width) do |t|
          t.row(0).font_style = :bold
          t.row(0).background_color = "F1F5F9"
          t.row(0).text_color = "1E293B"
          t.row(0).size = 9
          t.cells.padding = [6, 8]
          t.cells.size = 8
          t.cells.border_width = 0.5
          t.cells.border_color = "E2E8F0"
          t.columns(0).align = :center
          t.columns(5).align = :right
        end

        pdf.move_down 15
      end

      def add_summary
        y_pos = pdf.cursor

        pdf.bounding_box([pdf.bounds.width - 200, y_pos], width: 200) do
          pdf.fill_color "F8FAFC"
          pdf.fill_rounded_rectangle([0, pdf.cursor], 200, 50, 4)
          pdf.fill_color "1E293B"
          pdf.move_down 10
          pdf.indent(10) do
            pdf.text "TOTAL DISBURSED", size: 8, style: :bold
            pdf.move_down 4
            formatted_amount = "#{payout.currency} #{format('%.2f', payout.amount)}"
            pdf.text formatted_amount, size: 14, style: :bold, color: "4F46E5"
          end
        end

        pdf.move_down 30
      end

      def add_footer
        pdf.fill_color "94A3B8"
        pdf.text_box(
          "Thank you for being a valued Deskbolic affiliate partner. For questions regarding this payout statement, please contact support@capiller.com.",
          at: [0, 30],
          width: pdf.bounds.width,
          height: 30,
          size: 8,
          align: :center
        )
      end

      def add_divider
        pdf.stroke_color "E2E8F0"
        pdf.stroke_horizontal_rule
        pdf.move_down 12
      end

      def attach_pdf
        payout.invoice_pdf.attach(
          io: StringIO.new(pdf.render),
          filename: "payout-statement-#{payout.code}.pdf",
          content_type: "application/pdf"
        )
      end
    end
  end
end
