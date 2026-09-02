# frozen_string_literal: true

module Seeds
  module Data
    module ProductDocs
      module BillingAndSubscriptions
        def self.category
          {
            key: :billing_and_subscriptions,
            icon_key: "credit-card",
            position: 10,
            translations: {
              en: {
                name: "Billing, Plans & AI Credits",
                description: "Manage subscription plans, payment methods, invoices, agent seat licenses, and AI wallet credit top-ups."
              },
              de: {
                name: "Abrechnung, Pläne & KI-Guthaben",
                description: "Verwalten Sie Abonnements, Zahlungsmethoden, Rechnungen und KI-Guthaben."
              },
              es: {
                name: "Facturación, Planes y Créditos de IA",
                description: "Gestione planes de suscripción, métodos de pago, facturas y saldo de créditos de IA."
              },
              fr: {
                name: "Facturation, Forfaits et Crédits IA",
                description: "Gérez vos abonnements, modes de paiement, factures et recharges de crédits IA."
              },
              "pt-BR": {
                name: "Faturamento, Planos e Créditos de IA",
                description: "Gerencie planos de assinatura, formas de pagamento, faturas e recargas de créditos de IA."
              },
              ar: {
                name: "الفواتير والاشتراكات ورصيد الذكاء الاصطناعي",
                description: "إدارة خطط الاشتراك، وطرق الدفع، والفواتير، وتراخيص الوكلاء، وشحن رصيد محفظة الذكاء الاصطناعي."
              },
              ko: {
                name: "요금제, 결제 및 AI 크레딧",
                description: "구독 요금제 관리, 결제 수단 등록, 세금계산서/인보이스 조회 및 AI 크레딧 충전 가이드입니다."
              }
            }
          }
        end

        def self.articles
          [
            {
              key: :managing_plans_and_invoices,
              position: 1,
              translations: {
                en: {
                  title: "Managing Subscriptions, Payment Methods & Invoices",
                  content: <<~HTML
                    <p>Learn how to manage your workspace subscription, upgrade or downgrade plans, and download VAT invoices.</p>
                    <h3>Managing Your Subscription</h3>
                    <p>Navigate to <strong>Settings &rarr; Billing</strong> to view your active plan, current seat count, billing renewal date, and past PDF invoices.</p>
                    <h3>AI Wallet Credits</h3>
                    <p>AI agent conversations and live translation features consume AI Wallet credits. You can enable auto-recharge under <strong>Settings &rarr; AI Wallet</strong> to prevent service interruptions.</p>
                  HTML
                },
                de: {
                  title: "Abonnements, Zahlungsarten & Rechnungen verwalten",
                  content: "<p>Verwalten Sie Abonnements, Agentenplätze und KI-Guthaben unter Einstellungen &rarr; Abrechnung.</p>"
                },
                es: {
                  title: "Gestión de Suscripciones, Métodos de Pago y Facturas",
                  content: "<p>Gestione su suscripción, licencias de agentes y recargas de IA en Configuración &rarr; Facturación.</p>"
                },
                fr: {
                  title: "Gestion des Abonnements, Factures et Crédits",
                  content: "<p>Gérez vos forfaits, vos licences et vos recharges de crédits IA dans Paramètres &rarr; Facturation.</p>"
                },
                "pt-BR": {
                  title: "Gerenciando Assinaturas, Faturas e Créditos",
                  content: "<p>Gerencie seu plano, licenças de atendentes e recargas de IA em Configurações &rarr; Faturamento.</p>"
                },
                ar: {
                  title: "إدارة الاشتراكات وطرق الدفع والفواتير",
                  content: "<p>أدر خطة اشتراك مساحة العمل وتراخيص المقاعد وشحن رصيد الذكاء الاصطناعي من الإعدادات &rarr; الفواتير.</p>"
                },
                ko: {
                  title: "구독 요금제, 결제 수단 및 인보이스 관리",
                  content: "<p><strong>설정 &rarr; 요금 및 결제</strong>에서 현재 플랜, 상담원 라이선스 수량, 영수증(인보이스) 다운로드 및 AI 크레딧 충전을 관리합니다.</p>"
                }
              }
            }
          ]
        end
      end
    end
  end
end
