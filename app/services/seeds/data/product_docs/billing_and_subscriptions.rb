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
                description: "Review workspace billing, payment methods, subscription details, and wallet or AI credit balances."
              },
              de: {
                name: "Abrechnung, Pläne & KI-Guthaben",
                description: "Prüfen Sie Abrechnung, Zahlungsmethoden, Abonnementdetails und Guthaben."
              },
              es: {
                name: "Facturación, Planes y Créditos de IA",
                description: "Revise la facturación, los métodos de pago, los detalles de la suscripción y los saldos."
              },
              fr: {
                name: "Facturation, Forfaits et Crédits IA",
                description: "Consultez la facturation, les moyens de paiement, l'abonnement et les soldes du portefeuille."
              },
              "pt-BR": {
                name: "Faturamento, Planos e Créditos de IA",
                description: "Consulte faturamento, formas de pagamento, assinatura e saldos da carteira."
              },
              ar: {
                name: "الفواتير والاشتراكات ورصيد الذكاء الاصطناعي",
                description: "راجع الفوترة وطرق الدفع وتفاصيل الاشتراك وأرصدة المحفظة والذكاء الاصطناعي."
              },
              ko: {
                name: "요금제, 결제 및 AI 크레딧",
                description: "워크스페이스 청구, 결제 수단, 구독 정보, 지갑 및 AI 크레딧 잔액을 확인합니다."
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
                    <p>Use the billing page to review your workspace subscription, payment methods, wallet balance, AI credits, and available billing actions.</p>
                    <ol>
                      <li>Open <strong>Settings &rarr; Billing &amp; Subscription</strong>.</li>
                      <li>Review the subscription and billing-cycle information shown for your workspace.</li>
                      <li>Use <strong>Payment Methods</strong> to add a card, set a default payment method, or remove an existing method.</li>
                      <li>Use the wallet and AI credit sections to review balances and choose a top-up amount when needed.</li>
                    </ol>
                    <p>Available plan changes, invoices, and payment actions depend on your account's current billing state. Follow the options shown on the page; do not assume an automatic wallet or AI credit recharge is enabled.</p>
                  HTML
                },
                de: {
                  title: "Abonnements, Zahlungsarten & Rechnungen verwalten",
                  content: "<p>Auf der Abrechnungsseite sehen Sie das Abonnement, Zahlungsmethoden sowie Wallet- und KI-Guthaben Ihres Arbeitsbereichs.</p><ol><li>Öffnen Sie <strong>Settings → Billing &amp; Subscription</strong>.</li><li>Prüfen Sie Abonnement und Abrechnungszeitraum.</li><li>Fügen Sie unter <strong>Payment Methods</strong> eine Karte hinzu, legen Sie eine Standardkarte fest oder entfernen Sie eine Karte.</li><li>Prüfen Sie Wallet- und KI-Guthaben. Wählen Sie bei Bedarf einen der angezeigten Aufladebeträge.</li></ol><p>Planänderungen, Rechnungen und Zahlungsaktionen hängen vom aktuellen Kontostatus ab. Folgen Sie den angezeigten Optionen; eine automatische Aufladung ist nicht vorausgesetzt.</p>"
                },
                es: {
                  title: "Gestión de Suscripciones, Métodos de Pago y Facturas",
                  content: "<p>La página de facturación muestra la suscripción, los métodos de pago y los saldos de cartera y créditos de IA del espacio de trabajo.</p><ol><li>Abra <strong>Settings → Billing &amp; Subscription</strong>.</li><li>Revise la suscripción y el ciclo de facturación actuales.</li><li>En <strong>Payment Methods</strong>, agregue una tarjeta, establezca la predeterminada o quite una tarjeta.</li><li>Consulte los saldos y elija uno de los importes de recarga disponibles si lo necesita.</li></ol><p>Los cambios de plan, las facturas y las acciones de pago dependen del estado de la cuenta. Siga las opciones que aparecen; no dé por hecho que la recarga automática está activada.</p>"
                },
                fr: {
                  title: "Gestion des Abonnements, Factures et Crédits",
                  content: "<p>La page de facturation présente l'abonnement, les moyens de paiement et les soldes du portefeuille et des crédits IA de l'espace.</p><ol><li>Ouvrez <strong>Settings → Billing &amp; Subscription</strong>.</li><li>Consultez l'abonnement et la période de facturation.</li><li>Dans <strong>Payment Methods</strong>, ajoutez une carte, définissez la carte par défaut ou supprimez-en une.</li><li>Consultez les soldes et choisissez un montant de recharge proposé si nécessaire.</li></ol><p>Les changements de forfait, factures et paiements dépendent de l'état du compte. Suivez les options affichées ; ne supposez pas que la recharge automatique est activée.</p>"
                },
                "pt-BR": {
                  title: "Gerenciando Assinaturas, Faturas e Créditos",
                  content: "<p>A página de cobrança mostra a assinatura, os meios de pagamento e os saldos da carteira e de créditos de IA do espaço de trabalho.</p><ol><li>Abra <strong>Settings → Billing &amp; Subscription</strong>.</li><li>Confira a assinatura e o ciclo de cobrança.</li><li>Em <strong>Payment Methods</strong>, adicione um cartão, defina o padrão ou remova um cartão.</li><li>Consulte os saldos e escolha um valor de recarga disponível se necessário.</li></ol><p>Alterações de plano, faturas e pagamentos dependem do estado da conta. Use as opções exibidas; não presuma que a recarga automática está ativada.</p>"
                },
                ar: {
                  title: "إدارة الاشتراكات وطرق الدفع والفواتير",
                  content: "<p>تعرض صفحة الفوترة الاشتراك وطرق الدفع وأرصدة المحفظة والذكاء الاصطناعي لمساحة العمل.</p><ol><li>افتح <strong>Settings → Billing &amp; Subscription</strong>.</li><li>راجع الاشتراك ودورة الفوترة الحالية.</li><li>من <strong>Payment Methods</strong> أضف بطاقة أو عيّن البطاقة الافتراضية أو أزل بطاقة.</li><li>راجع الأرصدة واختر مبلغ شحن معروضًا عند الحاجة.</li></ol><p>تعتمد تغييرات الخطة والفواتير وإجراءات الدفع على حالة الحساب. اتبع الخيارات الظاهرة ولا تفترض تفعيل الشحن التلقائي.</p>"
                },
                ko: {
                  title: "구독 요금제, 결제 수단 및 인보이스 관리",
                  content: "<p>결제 페이지에서 워크스페이스 구독, 결제 수단, 지갑 및 AI 크레딧 잔액을 확인할 수 있습니다.</p><ol><li><strong>Settings → Billing &amp; Subscription</strong>을 엽니다.</li><li>현재 구독과 결제 주기를 확인합니다.</li><li><strong>Payment Methods</strong>에서 카드를 추가하거나 기본 카드로 지정하거나 삭제합니다.</li><li>잔액을 확인하고 필요하면 화면에 표시된 충전 금액을 선택합니다.</li></ol><p>요금제 변경, 인보이스와 결제 작업은 계정 상태에 따라 달라집니다. 화면에 제공되는 옵션을 따르고 자동 충전이 활성화되어 있다고 가정하지 마세요.</p>"
                }
              }
            }
          ]
        end
      end
    end
  end
end
