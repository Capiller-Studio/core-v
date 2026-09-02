# frozen_string_literal: true

module Seeds
  module Data
    module ProductDocs
      module GettingStarted
        def self.category
          {
            key: :getting_started,
            icon_key: "rocket",
            position: 1,
            guide_mode: true,
            translations: {
              en: {
                name: "Getting Started",
                description: "Everything you need to set up your Deskbolic workspace, invite your team, and begin delivering exceptional customer support."
              },
              de: {
                name: "Erste Schritte",
                description: "Alles, was Sie brauchen, um Ihren Deskbolic-Arbeitsbereich einzurichten und Ihr Team einzuladen."
              },
              es: {
                name: "Primeros Pasos",
                description: "Todo lo que necesita para configurar su espacio de trabajo en Deskbolic e invitar a su equipo."
              },
              fr: {
                name: "Mise en route",
                description: "Tout ce dont vous avez besoin pour configurer votre espace Deskbolic et inviter votre équipe."
              },
              "pt-BR": {
                name: "Primeiros Passos",
                description: "Tudo o que você precisa para configurar seu espaço de trabalho no Deskbolic e convidar sua equipe."
              },
              ar: {
                name: "دليل البدء السريع",
                description: "كل ما تحتاجه لإعداد مساحة عمل Deskbolic، ودعوة فريقك، وبدء تقديم دعم استثنائي للعملاء."
              },
              ko: {
                name: "시작하기",
                description: "Deskbolic 워크스페이스를 설정하고 팀원을 초대하여 고객 지원을 시작하는 데 필요한 모든 가이드입니다."
              }
            }
          }
        end

        def self.articles
          [
            {
              key: :quick_start_guide,
              position: 1,
              translations: {
                en: {
                  title: "Quick Start Guide & Onboarding",
                  content: <<~HTML
                    <p>Welcome to <strong>Deskbolic</strong>! This guide will walk you through setting up your customer support workspace in under 5 minutes.</p>
                    <h3>Step 1: Configure Your Workspace Profile</h3>
                    <p>Navigate to <strong>Settings &rarr; General</strong> to set your organization name, default currency, time zone, and support email address.</p>
                    <h3>Step 2: Connect Your First Communication Channel</h3>
                    <p>Go to <strong>Settings &rarr; Inboxes</strong> and click <strong>+ Add Inbox</strong>. Choose from Email, Web Chat Widget, WhatsApp Business, Facebook Messenger, or Instagram Direct.</p>
                    <h3>Step 3: Invite Your Support Team</h3>
                    <p>Navigate to <strong>Settings &rarr; Agents</strong> to invite team members with specific roles (Owner, Admin, Agent). Team members will receive an instant email invitation to set their password.</p>
                  HTML
                },
                de: {
                  title: "Schnellstartanleitung & Onboarding",
                  content: <<~HTML
                    <p>Willkommen bei <strong>Deskbolic</strong>! Diese Anleitung führt Sie in unter 5 Minuten durch die Einrichtung Ihres Support-Arbeitsbereichs.</p>
                    <h3>Schritt 1: Arbeitsbereich konfigurieren</h3>
                    <p>Gehen Sie zu <strong>Einstellungen &rarr; Allgemein</strong>, um den Namen Ihrer Organisation, Währung und Zeitzone festzulegen.</p>
                    <h3>Schritt 2: Kommunikationskanal verbinden</h3>
                    <p>Gehen Sie zu <strong>Einstellungen &rarr; Postfächer</strong> und fügen Sie E-Mail, Live-Chat oder WhatsApp hinzu.</p>
                    <h3>Schritt 3: Team einladen</h3>
                    <p>Laden Sie unter <strong>Einstellungen &rarr; Agenten</strong> Ihre Teammitglieder ein.</p>
                  HTML
                },
                es: {
                  title: "Guía de Inicio Rápido e Incorporación",
                  content: <<~HTML
                    <p>¡Bienvenido a <strong>Deskbolic</strong>! Esta guía le ayudará a configurar su espacio de trabajo de soporte al cliente en menos de 5 minutos.</p>
                    <h3>Paso 1: Configure su Espacio de Trabajo</h3>
                    <p>Vaya a <strong>Configuración &rarr; General</strong> para establecer el nombre de su organización, zona horaria y moneda.</p>
                    <h3>Paso 2: Conecte su Primer Canal</h3>
                    <p>Vaya a <strong>Configuración &rarr; Bandejas de Entrada</strong> y agregue correo electrónico, widget de chat o WhatsApp.</p>
                    <h3>Paso 3: Invite a su Equipo</h3>
                    <p>Invite a sus agentes desde <strong>Configuración &rarr; Agentes</strong>.</p>
                  HTML
                },
                fr: {
                  title: "Guide de Démarrage Rapide",
                  content: <<~HTML
                    <p>Bienvenue sur <strong>Deskbolic</strong>! Ce guide vous aide à configurer votre espace de support en moins de 5 minutes.</p>
                    <h3>Étape 1: Configurer l'espace de travail</h3>
                    <p>Accédez à <strong>Paramètres &rarr; Général</strong> pour définir le nom de votre organisation et le fuseau horaire.</p>
                    <h3>Étape 2: Connecter un canal de support</h3>
                    <p>Ajoutez un canal e-mail, widget web ou WhatsApp dans <strong>Paramètres &rarr; Boîtes de réception</strong>.</p>
                    <h3>Étape 3: Inviter votre équipe</h3>
                    <p>Invitez vos collaborateurs depuis <strong>Paramètres &rarr; Agents</strong>.</p>
                  HTML
                },
                "pt-BR": {
                  title: "Guia de Início Rápido e Integração",
                  content: <<~HTML
                    <p>Bem-vindo ao <strong>Deskbolic</strong>! Este guia ajudará você a configurar seu espaço de atendimento em menos de 5 minutos.</p>
                    <h3>Passo 1: Configurar seu Espaço de Trabalho</h3>
                    <p>Acesse <strong>Configurações &rarr; Geral</strong> para definir o nome da sua empresa, fuso horário e moeda.</p>
                    <h3>Passo 2: Conectar seu Primeiro Canal</h3>
                    <p>Adicione e-mail, widget de chat ou WhatsApp em <strong>Configurações &rarr; Caixas de Entrada</strong>.</p>
                    <h3>Passo 3: Convidar sua Equipe</h3>
                    <p>Convide atendentes em <strong>Configurações &rarr; Atendentes</strong>.</p>
                  HTML
                },
                ar: {
                  title: "دليل البدء السريع والإعداد",
                  content: <<~HTML
                    <p>مرحبًا بك في <strong>Deskbolic</strong>! سيساعدك هذا الدليل في إعداد مساحة عمل دعم العملاء في أقل من 5 دقائق.</p>
                    <h3>الخطوة 1: تكوين مساحة العمل</h3>
                    <p>انتقل إلى <strong>الإعدادات &rarr; عام</strong> لتعيين اسم مؤسستك والمنطقة الزمنية والعملة.</p>
                    <h3>الخطوة 2: ربط قناة الاتصال الأولى</h3>
                    <p>انتقل إلى <strong>الإعدادات &rarr; صناديق الوارد</strong> وأضف البريد الإلكتروني أو الدردشة المباشرة أو WhatsApp.</p>
                    <h3>الخطوة 3: دعوة فريق الدعم</h3>
                    <p>قم بدعوة أعضاء الفريق من <strong>الإعدادات &rarr; الوكلاء</strong>.</p>
                  HTML
                },
                ko: {
                  title: "빠른 시작 가이드 및 온보딩",
                  content: <<~HTML
                    <p><strong>Deskbolic</strong>에 오신 것을 환영합니다! 5분 만에 고객 지원 워크스페이스를 설정하는 방법을 안내합니다.</p>
                    <h3>1단계: 워크스페이스 기본 설정</h3>
                    <p><strong>설정 &rarr; 일반</strong>으로 이동하여 조직 이름, 기본 통화, 시간대를 설정합니다.</p>
                    <h3>2단계: 첫 번째 상담 채널 연결</h3>
                    <p><strong>설정 &rarr; 받은 편지함</strong>에서 이메일, 웹 채팅 위젯 또는 WhatsApp 채널을 생성합니다.</p>
                    <h3>3단계: 상담원 및 팀원 초대</h3>
                    <p><strong>설정 &rarr; 상담원</strong>에서 팀원을 초대하고 역할을 부여합니다.</p>
                  HTML
                }
              }
            },
            {
              key: :navigation_and_command_palette,
              position: 2,
              translations: {
                en: {
                  title: "Workspace Navigation & Command Palette (⌘K)",
                  content: <<~HTML
                    <p>Deskbolic is built for lightning-fast agent productivity. Learn how to navigate your workspace efficiently using keyboard shortcuts and global search.</p>
                    <h3>Global Command Palette (⌘K / Ctrl+K)</h3>
                    <p>Press <kbd>⌘K</kbd> (Mac) or <kbd>Ctrl+K</kbd> (Windows/Linux) anywhere in the application to instantly search across conversations, customer profiles, knowledge base articles, or jump directly to specific settings pages.</p>
                    <h3>Switching Workspaces</h3>
                    <p>Click your avatar in the bottom sidebar and select <strong>All Workspaces</strong> to view and switch between your customer support accounts with a single click.</p>
                  HTML
                },
                de: {
                  title: "Navigation & Befehlsleiste (⌘K)",
                  content: <<~HTML
                    <p>Verwenden Sie die globale Befehlsleiste (<kbd>⌘K</kbd> / <kbd>Strg+K</kbd>), um blitzschnell nach Konversationen, Kunden und Einstellungen zu suchen.</p>
                  HTML
                },
                es: {
                  title: "Navegación y Paleta de Comandos (⌘K)",
                  content: <<~HTML
                    <p>Presione <kbd>⌘K</kbd> o <kbd>Ctrl+K</kbd> para abrir la paleta de comandos y buscar instantáneamente conversaciones, clientes y configuraciones.</p>
                  HTML
                },
                fr: {
                  title: "Navigation et Palette de Commandes (⌘K)",
                  content: <<~HTML
                    <p>Appuyez sur <kbd>⌘K</kbd> ou <kbd>Ctrl+K</kbd> pour rechercher instantanément des conversations, des clients et accéder aux paramètres.</p>
                  HTML
                },
                "pt-BR": {
                  title: "Navegação e Paleta de Comandos (⌘K)",
                  content: <<~HTML
                    <p>Pressione <kbd>⌘K</kbd> ou <kbd>Ctrl+K</kbd> para pesquisar instantaneamente conversas, clientes e configurações.</p>
                  HTML
                },
                ar: {
                  title: "التنقل ولوحة الأوامر السريعة (⌘K)",
                  content: <<~HTML
                    <p>اضغط على <kbd>⌘K</kbd> أو <kbd>Ctrl+K</kbd> لفتح لوحة الأوامر والبحث الفوري في المحادثات وجهات الاتصال والإعدادات.</p>
                  HTML
                },
                ko: {
                  title: "워크스페이스 탐색 및 커맨드 팔레트 (⌘K)",
                  content: <<~HTML
                    <p><kbd>⌘K</kbd> 또는 <kbd>Ctrl+K</kbd> 단축키를 눌러 대화, 고객 연락처, 도움말 문서를 즉시 검색하고 원하는 메뉴로 이동할 수 있습니다.</p>
                  HTML
                }
              }
            }
          ]
        end
      end
    end
  end
end
