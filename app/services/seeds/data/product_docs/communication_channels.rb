# frozen_string_literal: true

module Seeds
  module Data
    module ProductDocs
      module CommunicationChannels
        def self.category
          {
            key: :communication_channels,
            icon_key: "radio",
            position: 3,
            translations: {
              en: {
                name: "Communication Channels",
                description: "Connect Email, Web Chat Widget, WhatsApp Business, Facebook Messenger, Instagram Direct, and custom API channels."
              },
              de: {
                name: "Kommunikationskanäle",
                description: "Verbinden Sie E-Mail, Live-Chat-Widget, WhatsApp Business, Instagram und Facebook Messenger."
              },
              es: {
                name: "Canales de Comunicación",
                description: "Conecte correo electrónico, widget de chat web, WhatsApp Business, Facebook Messenger e Instagram Direct."
              },
              fr: {
                name: "Canaux de Communication",
                description: "Connectez vos canaux e-mail, widget web, WhatsApp Business, Facebook et Instagram."
              },
              "pt-BR": {
                name: "Canais de Atendimento",
                description: "Conecte e-mail, widget de chat web, WhatsApp Business, Facebook Messenger e Instagram Direct."
              },
              ar: {
                name: "قنوات الاتصال والدعم",
                description: "اربط البريد الإلكتروني، وودجة الدردشة للموقع، وWhatsApp Business، وFacebook Messenger، وInstagram Direct."
              },
              ko: {
                name: "상담 채널 연동",
                description: "이메일, 웹 채팅 위젯, WhatsApp 비즈니스, 페이스북 메신저, 인스타그램 및 커스텀 API 채널 연동 가이드입니다."
              }
            }
          }
        end

        def self.articles
          [
            {
              key: :email_channel_setup,
              position: 1,
              translations: {
                en: {
                  title: "Setting Up Email Channels & Forwarding",
                  content: <<~HTML
                    <p>Connect your existing support email addresses (e.g. <code>support@yourcompany.com</code>) using automatic email forwarding or custom SMTP/IMAP credentials.</p>
                    <h3>Option A: Automated Inbound Forwarding</h3>
                    <p>Deskbolic generates a dedicated inbound address (e.g. <code>support-xyz@inbound.deskbolic.app</code>). Simply configure a forwarding rule in Google Workspace, Microsoft 365, or your email host.</p>
                    <h3>Option B: Custom SMTP &amp; IMAP</h3>
                    <p>Enter your mail server host, port, username, and TLS settings under <strong>Settings &rarr; Inboxes &rarr; Email Settings</strong> for full deliverability control.</p>
                  HTML
                },
                de: {
                  title: "E-Mail-Kanäle & Weiterleitung einrichten",
                  content: "<p>Verbinden Sie Ihre Support-E-Mail-Adresse über automatische Weiterleitung oder benutzerdefinierte SMTP/IMAP-Einstellungen.</p>"
                },
                es: {
                  title: "Configuración de Canales de Correo Electrónico",
                  content: "<p>Conecte sus direcciones de correo de soporte mediante reenvío automático o credenciales SMTP/IMAP personalizadas.</p>"
                },
                fr: {
                  title: "Configuration des Canaux E-mail",
                  content: "<p>Connectez vos adresses e-mail de support via le transfert automatique ou vos propres serveurs SMTP/IMAP.</p>"
                },
                "pt-BR": {
                  title: "Configuração de Canais de E-mail",
                  content: "<p>Conecte seus e-mails de atendimento por encaminhamento automático ou servidores SMTP/IMAP próprios.</p>"
                },
                ar: {
                  title: "إعداد قنوات البريد الإلكتروني وإعادة التوجيه",
                  content: "<p>اربط عناوين البريد الإلكتروني للدعم عبر إعادة التوجيه التلقائي أو إعدادات خادم SMTP/IMAP المخصصة.</p>"
                },
                ko: {
                  title: "이메일 채널 및 자동 전달 설정",
                  content: "<p>자동 포워딩(전달) 규칙 또는 자체 SMTP/IMAP 서버 설정을 통해 고객 지원 이메일(support@company.com)을 연동합니다.</p>"
                }
              }
            },
            {
              key: :web_widget_installation,
              position: 2,
              translations: {
                en: {
                  title: "Web Chat Widget Installation & Styling",
                  content: <<~HTML
                    <p>Embed the lightweight Deskbolic live chat widget on your website or web application with a single snippet of JavaScript.</p>
                    <h3>Installation Snippet</h3>
                    <pre><code class="language-html">&lt;script&gt;
  (function(d,t) {
    var g=d.createElement(t),s=d.getElementsByTagName(t)[0];
    g.src="https://widget.deskbolic.com/widget.js";
    g.defer = true;
    s.parentNode.insertBefore(g,s);
    g.onload=function(){
      window.deskbolicSDK.run({
        websiteToken: 'YOUR_WIDGET_TOKEN'
      })
    }
  })(document,"script");
&lt;/script&gt;</code></pre>
                    <h3>Customization</h3>
                    <p>Customize widget colors, greeting headers, avatar icons, launcher position, and pre-chat contact forms in <strong>Settings &rarr; Inboxes &rarr; Web Widget</strong>.</p>
                  HTML
                },
                de: {
                  title: "Web-Chat-Widget Installation & Design",
                  content: "<p>Integrieren Sie das Deskbolic Live-Chat-Widget mit einem kurzen JavaScript-Snippet auf Ihrer Website.</p>"
                },
                es: {
                  title: "Instalación del Widget de Chat Web",
                  content: "<p>Incruste el widget de chat en vivo de Deskbolic en su sitio web con un sencillo fragmento de JavaScript.</p>"
                },
                fr: {
                  title: "Installation du Widget de Chat Web",
                  content: "<p>Intégrez le widget de chat en direct Deskbolic sur votre site web avec un court extrait JavaScript.</p>"
                },
                "pt-BR": {
                  title: "Instalação do Widget de Chat Web",
                  content: "<p>Incorpore o widget de chat ao vivo do Deskbolic em seu site com um simples script JavaScript.</p>"
                },
                ar: {
                  title: "تثبيت وتخصيص ودجة الدردشة للموقع",
                  content: "<p>قم بتضمين ودجة الدردشة المباشرة من Deskbolic في موقع الويب الخاص بك باستخدام مقتطف كود JavaScript بسيط.</p>"
                },
                ko: {
                  title: "웹 채팅 위젯 설치 및 커스텀 디자인",
                  content: "<p>간단한 JavaScript 코드 스니펫 한 줄로 웹사이트에 Deskbolic 실시간 라이브 채팅 위젯을 임베드하고 디자인을 맞춤 설정합니다.</p>"
                }
              }
            },
            {
              key: :whatsapp_channel_integration,
              position: 3,
              translations: {
                en: {
                  title: "WhatsApp Business API Integration",
                  content: <<~HTML
                    <p>Provide direct customer support over WhatsApp with official Meta WhatsApp Cloud API integration.</p>
                    <h3>Prerequisites</h3>
                    <ul>
                      <li>A Meta Business Manager account.</li>
                      <li>A verified phone number not currently registered with consumer WhatsApp.</li>
                      <li>WhatsApp Business Cloud API credentials (Phone Number ID, Business Account ID, System User Access Token).</li>
                    </ul>
                  HTML
                },
                de: {
                  title: "WhatsApp Business API-Integration",
                  content: "<p>Bieten Sie Kundensupport über WhatsApp mit der offiziellen Meta Cloud-API an.</p>"
                },
                es: {
                  title: "Integración de WhatsApp Business API",
                  content: "<p>Brinde soporte al cliente a través de WhatsApp con la API oficial de Meta Cloud.</p>"
                },
                fr: {
                  title: "Intégration de l'API WhatsApp Business",
                  content: "<p>Offrez un support client sur WhatsApp grâce à l'intégration officielle Meta Cloud API.</p>"
                },
                "pt-BR": {
                  title: "Integração do WhatsApp Business API",
                  content: "<p>Ofereça suporte pelo WhatsApp com a integração oficial da Meta Cloud API.</p>"
                },
                ar: {
                  title: "التكامل مع WhatsApp Business API",
                  content: "<p>قدم دعمًا مباشرًا للعملاء عبر WhatsApp باستخدام تكامل Meta WhatsApp Cloud API الرسمي.</p>"
                },
                ko: {
                  title: "WhatsApp 비즈니스 API 연동",
                  content: "<p>공식 Meta WhatsApp Cloud API를 통해 전 세계 고객에게 WhatsApp 메신저 실시간 상담을 제공합니다.</p>"
                }
              }
            }
          ]
        end
      end
    end
  end
end
