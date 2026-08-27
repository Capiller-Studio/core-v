# frozen_string_literal: true

# Company: TECHBOLIC SOLUTIONS (PRIVATE) LIMITED
# VERSION: 2.0.0
# Website: https://techbolic.com/

module Accounts
  class DefaultCustomFieldsCreator < ApplicationService
    attr_reader :account

    FIELD_DEFINITIONS = {
      "name" => {
        entity_type: :customer,
        field_type: :text,
        required: true,
        mapped_to: "customer.name",
        translations: {
          "en" => { label: "Full Name", placeholder: "e.g. Jane Doe" },
          "es" => { label: "Nombre completo", placeholder: "p. ej. María García" },
          "de" => { label: "Vollständiger Name", placeholder: "z. B. Max Mustermann" },
          "fr" => { label: "Nom complet", placeholder: "ex. Marie Dupont" },
          "pt-BR" => { label: "Nome completo", placeholder: "ex. Maria Silva" },
          "ar" => { label: "الاسم الكامل", placeholder: "مثال: أحمد محمد" },
          "ko" => { label: "성명", placeholder: "예: 홍길동" }
        }
      },
      "email" => {
        entity_type: :customer,
        field_type: :email,
        required: true,
        mapped_to: "customer.email",
        translations: {
          "en" => { label: "Email Address", placeholder: "name@example.com" },
          "es" => { label: "Correo electrónico", placeholder: "nombre@ejemplo.com" },
          "de" => { label: "E-Mail-Adresse", placeholder: "name@beispiel.de" },
          "fr" => { label: "Adresse e-mail", placeholder: "nom@exemple.com" },
          "pt-BR" => { label: "Endereço de e-mail", placeholder: "nome@exemplo.com" },
          "ar" => { label: "البريد الإلكتروني", placeholder: "name@example.com" },
          "ko" => { label: "이메일 주소", placeholder: "name@example.com" }
        }
      },
      "subject" => {
        entity_type: :conversation,
        field_type: :text,
        required: true,
        mapped_to: "conversation.title",
        translations: {
          "en" => { label: "Subject", placeholder: "How can we help?" },
          "es" => { label: "Asunto", placeholder: "¿En qué podemos ayudarte?" },
          "de" => { label: "Betreff", placeholder: "Wie können wir helfen?" },
          "fr" => { label: "Sujet", placeholder: "Comment pouvons-nous vous aider ?" },
          "pt-BR" => { label: "Assunto", placeholder: "Como podemos ajudar?" },
          "ar" => { label: "الموضوع", placeholder: "كيف يمكننا مساعدتك؟" },
          "ko" => { label: "제목", placeholder: "무엇을 도와드릴까요?" }
        }
      },
      "message" => {
        entity_type: :conversation,
        field_type: :textarea,
        required: true,
        mapped_to: "message.content",
        translations: {
          "en" => { label: "Message", placeholder: "Type your message here..." },
          "es" => { label: "Mensaje", placeholder: "Escribe tu mensaje aquí..." },
          "de" => { label: "Nachricht", placeholder: "Geben Sie hier Ihre Nachricht ein..." },
          "fr" => { label: "Message", placeholder: "Écrivez votre message ici..." },
          "pt-BR" => { label: "Mensagem", placeholder: "Digite sua mensagem aqui..." },
          "ar" => { label: "الرسالة", placeholder: "اكتب رسالتك هنا..." },
          "ko" => { label: "메시지", placeholder: "메시지를 입력하세요..." }
        }
      },
      "priority" => {
        entity_type: :conversation,
        field_type: :select,
        required: false,
        mapped_to: "conversation.priority",
        translations: {
          "en" => {
            label: "Priority",
            options: [
              { "value" => "low", "label" => "Low" },
              { "value" => "medium", "label" => "Medium" },
              { "value" => "high", "label" => "High" },
              { "value" => "urgent", "label" => "Urgent" }
            ]
          },
          "es" => {
            label: "Prioridad",
            options: [
              { "value" => "low", "label" => "Baja" },
              { "value" => "medium", "label" => "Media" },
              { "value" => "high", "label" => "Alta" },
              { "value" => "urgent", "label" => "Urgente" }
            ]
          },
          "de" => {
            label: "Priorität",
            options: [
              { "value" => "low", "label" => "Niedrig" },
              { "value" => "medium", "label" => "Mittel" },
              { "value" => "high", "label" => "Hoch" },
              { "value" => "urgent", "label" => "Dringend" }
            ]
          },
          "fr" => {
            label: "Priorité",
            options: [
              { "value" => "low", "label" => "Basse" },
              { "value" => "medium", "label" => "Moyenne" },
              { "value" => "high", "label" => "Haute" },
              { "value" => "urgent", "label" => "Urgente" }
            ]
          },
          "pt-BR" => {
            label: "Prioridade",
            options: [
              { "value" => "low", "label" => "Baixa" },
              { "value" => "medium", "label" => "Média" },
              { "value" => "high", "label" => "Alta" },
              { "value" => "urgent", "label" => "Urgente" }
            ]
          },
          "ar" => {
            label: "الأولوية",
            options: [
              { "value" => "low", "label" => "منخفضة" },
              { "value" => "medium", "label" => "متوسطة" },
              { "value" => "high", "label" => "عالية" },
              { "value" => "urgent", "label" => "عاجلة" }
            ]
          },
          "ko" => {
            label: "우선순위",
            options: [
              { "value" => "low", "label" => "낮음" },
              { "value" => "medium", "label" => "보통" },
              { "value" => "high", "label" => "높음" },
              { "value" => "urgent", "label" => "긴급" }
            ]
          }
        }
      }
    }.freeze

    def initialize(account:)
      @account = account
    end

    def call
      account.with_shard do
        create_default_fields
      end
    end

    private

    def create_default_fields
      FIELD_DEFINITIONS.each do |key, config|
        create_field(key, config)
      end
    end

    def create_field(key, config)
      field = account.custom_fields.find_or_initialize_by(key: key)
      field.update!(
        entity_type: config[:entity_type],
        field_type: config[:field_type],
        required: config[:required],
        mapped_to: config[:mapped_to],
        system_provided: true
      )

      config[:translations].each do |locale, trans_data|
        translation = field.translations.find_or_initialize_by(locale: locale.to_s)
        translation.update!(
          label: trans_data[:label],
          placeholder: trans_data[:placeholder],
          options: trans_data[:options] || []
        )
      end
    end
  end
end
