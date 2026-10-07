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
                    <p>Welcome to <strong>Deskbolic</strong>. Use this checklist to prepare your workspace before your team starts handling conversations.</p>
                    <h3>Step 1: Configure Your Workspace Profile</h3>
                    <p>Open <strong>Settings &rarr; General Settings</strong> to review your workspace details and account time zone. Save any changes before moving on.</p>
                    <h3>Step 2: Connect Your First Communication Channel</h3>
                    <p>Open <strong>Settings &rarr; Channels</strong>, choose the channel type, and follow its setup page. Email, Web Widget, WhatsApp, Facebook, Instagram, Contact Form, and Custom channels have different prerequisites; use the matching channel guide below.</p>
                    <h3>Step 3: Invite Your Support Team</h3>
                    <p>Open <strong>Settings &rarr; Users (Teammates)</strong> to invite people who will handle support. Assign the appropriate role and add them to teams where needed.</p>
                    <h3>Step 4: Configure inbox settings</h3>
                    <p>Review the channel's <strong>Inbox Settings</strong> to choose collaborators and teams, enable auto-assignment if needed, and configure business hours, SLA policies, and available AI settings.</p>
                    <h3>Step 5: Send a test conversation</h3>
                    <p>Use your connected channel to send a test message. Confirm it appears in the inbox and that the right teammates can see and reply to it.</p>
                  HTML
                },
                de: {
                  title: "Schnellstartanleitung & Onboarding",
                  content: <<~HTML
                    <p>Willkommen bei <strong>Deskbolic</strong>. Nutzen Sie diese Checkliste, um Ihren Arbeitsbereich vorzubereiten, bevor Ihr Team Gespräche bearbeitet.</p>
                    <h3>Schritt 1: Arbeitsbereich konfigurieren</h3>
                    <p>Öffnen Sie <strong>Einstellungen &rarr; Allgemeine Einstellungen</strong>, um Ihre Arbeitsbereichsdaten und Zeitzone zu prüfen.</p>
                    <h3>Schritt 2: Kommunikationskanal verbinden</h3>
                    <p>Öffnen Sie <strong>Einstellungen &rarr; Kanäle</strong>, wählen Sie einen Kanaltyp und folgen Sie der jeweiligen Einrichtungsseite.</p>
                    <h3>Schritt 3: Team einladen</h3>
                    <p>Laden Sie Ihre Teammitglieder unter <strong>Einstellungen &rarr; Benutzer (Teammitglieder)</strong> ein.</p>
                    <h3>Schritt 4: Postfach einrichten</h3>
                    <p>Prüfen Sie die Postfacheinstellungen des Kanals und wählen Sie Mitarbeiter, Teams, Zuweisung sowie verfügbare Geschäftszeiten und SLA-Richtlinien.</p>
                    <h3>Schritt 5: Testnachricht senden</h3>
                    <p>Senden Sie eine Testnachricht und prüfen Sie, ob sie im Posteingang angezeigt wird und die richtigen Mitarbeiter antworten können.</p>
                  HTML
                },
                es: {
                  title: "Guía de Inicio Rápido e Incorporación",
                  content: <<~HTML
                    <p>¡Bienvenido a <strong>Deskbolic</strong>! Use esta lista para preparar su espacio antes de que el equipo atienda conversaciones.</p>
                    <h3>Paso 1: Configure su Espacio de Trabajo</h3>
                    <p>Abra <strong>Configuración &rarr; General Settings</strong> para revisar los datos del espacio de trabajo y la zona horaria de la cuenta.</p>
                    <h3>Paso 2: Conecte su Primer Canal</h3>
                    <p>Abra <strong>Configuración &rarr; Channels</strong>, elija el tipo de canal y siga la guía correspondiente. Cada canal tiene requisitos distintos.</p>
                    <h3>Paso 3: Invite a su Equipo</h3>
                    <p>Invite a sus compañeros desde <strong>Configuración &rarr; Users (Teammates)</strong> y asígneles el rol adecuado.</p>
                    <h3>Paso 4: Configure la bandeja</h3>
                    <p>Revise los ajustes para elegir colaboradores y equipos, y configure la asignación, el horario comercial y las políticas SLA disponibles.</p>
                    <h3>Paso 5: Envíe un mensaje de prueba</h3>
                    <p>Compruebe que un mensaje de prueba aparece en la bandeja y que los compañeros adecuados pueden responder.</p>
                  HTML
                },
                fr: {
                  title: "Guide de Démarrage Rapide",
                  content: <<~HTML
                    <p>Bienvenue sur <strong>Deskbolic</strong>! Utilisez cette liste pour préparer votre espace avant que l'équipe traite les conversations.</p>
                    <h3>Étape 1: Configurer l'espace de travail</h3>
                    <p>Ouvrez <strong>Paramètres &rarr; General Settings</strong> pour vérifier les informations de l'espace et le fuseau horaire du compte.</p>
                    <h3>Étape 2: Connecter un canal de support</h3>
                    <p>Ouvrez <strong>Paramètres &rarr; Channels</strong>, choisissez un type de canal et suivez son guide de configuration.</p>
                    <h3>Étape 3: Inviter votre équipe</h3>
                    <p>Invitez vos collègues depuis <strong>Paramètres &rarr; Users (Teammates)</strong> et attribuez-leur le rôle adapté.</p>
                    <h3>Étape 4: Configurer la boîte de réception</h3>
                    <p>Choisissez les collaborateurs et équipes, puis vérifiez l'attribution, les heures ouvrées et les politiques SLA disponibles.</p>
                    <h3>Étape 5: Envoyer un message de test</h3>
                    <p>Vérifiez que le message apparaît dans la boîte et que les bons collègues peuvent y répondre.</p>
                  HTML
                },
                "pt-BR": {
                  title: "Guia de Início Rápido e Integração",
                  content: <<~HTML
                    <p>Bem-vindo ao <strong>Deskbolic</strong>! Use esta lista para preparar seu espaço antes de a equipe atender conversas.</p>
                    <h3>Passo 1: Configurar seu Espaço de Trabalho</h3>
                    <p>Abra <strong>Configurações &rarr; General Settings</strong> para revisar os dados do espaço e o fuso horário da conta.</p>
                    <h3>Passo 2: Conectar seu Primeiro Canal</h3>
                    <p>Abra <strong>Configurações &rarr; Channels</strong>, escolha um tipo de canal e siga o guia de configuração correspondente.</p>
                    <h3>Passo 3: Convidar sua Equipe</h3>
                    <p>Convide colegas em <strong>Configurações &rarr; Users (Teammates)</strong> e atribua a função adequada.</p>
                    <h3>Passo 4: Configure a caixa de entrada</h3>
                    <p>Escolha colaboradores e equipes e revise a atribuição, o horário comercial e as políticas de SLA disponíveis.</p>
                    <h3>Passo 5: Envie uma mensagem de teste</h3>
                    <p>Confirme que a mensagem aparece na caixa de entrada e que as pessoas certas conseguem responder.</p>
                  HTML
                },
                ar: {
                  title: "دليل البدء السريع والإعداد",
                  content: <<~HTML
                    <p>مرحبًا بك في <strong>Deskbolic</strong>! استخدم هذه القائمة لإعداد مساحة العمل قبل أن يبدأ فريقك في التعامل مع المحادثات.</p>
                    <h3>الخطوة 1: تكوين مساحة العمل</h3>
                    <p>افتح <strong>الإعدادات &rarr; General Settings</strong> لمراجعة معلومات مساحة العمل والمنطقة الزمنية للحساب.</p>
                    <h3>الخطوة 2: ربط قناة الاتصال الأولى</h3>
                    <p>افتح <strong>الإعدادات &rarr; Channels</strong>، واختر نوع القناة واتبع دليل الإعداد الخاص بها.</p>
                    <h3>الخطوة 3: دعوة فريق الدعم</h3>
                    <p>ادعُ زملاءك من <strong>الإعدادات &rarr; Users (Teammates)</strong> وحدد الدور المناسب لهم.</p>
                    <h3>الخطوة 4: إعداد صندوق الوارد</h3>
                    <p>اختر المتعاونين والفرق، وراجع خيارات التعيين وساعات العمل وسياسات SLA المتاحة.</p>
                    <h3>الخطوة 5: إرسال رسالة اختبار</h3>
                    <p>تحقق من ظهور رسالة الاختبار في صندوق الوارد ومن قدرة الزملاء المناسبين على الرد.</p>
                  HTML
                },
                ko: {
                  title: "빠른 시작 가이드 및 온보딩",
                  content: <<~HTML
                    <p><strong>Deskbolic</strong>에 오신 것을 환영합니다. 팀이 상담을 시작하기 전에 이 체크리스트에 따라 워크스페이스를 준비하세요.</p>
                    <h3>1단계: 워크스페이스 기본 설정</h3>
                    <p><strong>설정 &rarr; General Settings</strong>에서 워크스페이스 정보와 계정 시간대를 확인합니다.</p>
                    <h3>2단계: 첫 번째 상담 채널 연결</h3>
                    <p><strong>설정 &rarr; Channels</strong>에서 채널 유형을 선택하고 해당 설정 가이드를 따릅니다. 채널마다 요구 사항이 다릅니다.</p>
                    <h3>3단계: 상담원 및 팀원 초대</h3>
                    <p><strong>설정 &rarr; Users (Teammates)</strong>에서 팀원을 초대하고 적절한 역할을 지정합니다.</p>
                    <h3>4단계: 받은 편지함 설정</h3>
                    <p>협업자와 팀을 선택하고 자동 할당, 업무 시간 및 사용 가능한 SLA 정책을 검토합니다.</p>
                    <h3>5단계: 테스트 메시지 보내기</h3>
                    <p>테스트 메시지가 받은 편지함에 표시되고 적절한 팀원이 답장할 수 있는지 확인합니다.</p>
                  HTML
                }
              }
            },
            {
              key: :account_timezone,
              position: 3,
              translations: {
                en: {
                  title: "Set Your Workspace Time Zone",
                  content: "<p>The account owner can configure the workspace time zone in <strong>Settings &rarr; General Settings</strong>. Select the appropriate region and city, then choose <strong>Save Changes</strong>. This setting does not currently convert every dashboard timestamp; some views may still display UTC. Business Hours groups have their own time-zone setting, so configure those separately for schedules that follow a different local time.</p>"
                },
                de: { title: "Zeitzone des Arbeitsbereichs festlegen", content: "<p>Der Kontoinhaber kann die Zeitzone unter <strong>Settings &rarr; General Settings</strong> ändern. Wählen Sie die passende Region und Stadt und klicken Sie auf <strong>Save Changes</strong>. Diese Einstellung konvertiert derzeit nicht alle Zeitstempel im Dashboard; manche Ansichten zeigen weiterhin UTC. Geschäftszeiten haben eine eigene Zeitzone.</p>" },
                es: { title: "Configurar la zona horaria del espacio de trabajo", content: "<p>El propietario puede cambiar la zona horaria en <strong>Settings &rarr; General Settings</strong>. Seleccione la región y ciudad correctas y pulse <strong>Save Changes</strong>. Actualmente, este ajuste no convierte todas las marcas de tiempo del panel; algunas vistas aún muestran UTC. Los horarios comerciales tienen una zona horaria propia.</p>" },
                fr: { title: "Définir le fuseau horaire de l'espace de travail", content: "<p>Le propriétaire peut modifier le fuseau horaire dans <strong>Settings &rarr; General Settings</strong>. Choisissez la région et la ville appropriées, puis cliquez sur <strong>Save Changes</strong>. Ce réglage ne convertit pas encore tous les horodatages du tableau de bord; certaines vues affichent toujours UTC. Les heures ouvrées ont leur propre fuseau.</p>" },
                "pt-BR": { title: "Definir o fuso horário do espaço de trabalho", content: "<p>O proprietário pode alterar o fuso em <strong>Settings &rarr; General Settings</strong>. Selecione a região e a cidade corretas e clique em <strong>Save Changes</strong>. Atualmente, essa configuração não converte todos os horários do painel; algumas telas ainda mostram UTC. Grupos de horário comercial têm um fuso próprio.</p>" },
                ar: { title: "تعيين المنطقة الزمنية لمساحة العمل", content: "<p>يمكن لمالك الحساب تغيير المنطقة الزمنية من <strong>Settings &rarr; General Settings</strong>. اختر المنطقة والمدينة المناسبتين ثم اضغط <strong>Save Changes</strong>. لا يحوّل هذا الإعداد حاليًا كل الطوابع الزمنية في لوحة التحكم؛ قد تعرض بعض الصفحات UTC. لساعات العمل منطقة زمنية مستقلة.</p>" },
                ko: { title: "워크스페이스 시간대 설정", content: "<p>계정 소유자는 <strong>Settings &rarr; General Settings</strong>에서 시간대를 변경할 수 있습니다. 올바른 지역과 도시를 선택하고 <strong>Save Changes</strong>를 누르세요. 현재 이 설정이 대시보드의 모든 시간을 변환하지는 않으며 일부 화면은 UTC를 표시합니다. 업무 시간 그룹에는 별도 시간대가 있습니다.</p>" }
              }
            },
            {
              key: :navigation_and_command_palette,
              position: 4,
              translations: {
                en: {
                  title: "Workspace Navigation & Command Palette (⌘K)",
                  content: <<~HTML
                    <p>Use the global search and quick actions to find conversations and messages or navigate to an available action.</p>
                    <h3>Search and Quick Actions</h3>
                    <ol>
                      <li>Press <kbd>⌘K</kbd> on Mac or <kbd>Ctrl+K</kbd> on Windows or Linux to open Smart Search.</li>
                      <li>Enter a search term. Matching quick actions appear alongside matching conversations and messages.</li>
                      <li>Select a result to open the conversation, message context, or action.</li>
                    </ol>
                    <h3>Switching Workspaces</h3>
                    <p>Use the account menu at the bottom of the sidebar and choose <strong>All Workspaces</strong> to view the workspaces available to your account.</p>
                  HTML
                },
                de: {
                  title: "Navigation & Befehlsleiste (⌘K)",
                  content: <<~HTML
                    <p>Öffnen Sie Smart Search mit <kbd>⌘K</kbd> oder <kbd>Strg+K</kbd>. Suchen Sie nach Konversationen und Nachrichten oder wählen Sie eine verfügbare Schnellaktion. Klicken Sie auf ein Ergebnis, um es zu öffnen. Über das Kontomenü unten in der Seitenleiste und <strong>All Workspaces</strong> sehen Sie die für Ihr Konto verfügbaren Arbeitsbereiche.</p>
                  HTML
                },
                es: {
                  title: "Navegación y Paleta de Comandos (⌘K)",
                  content: <<~HTML
                    <p>Pulse <kbd>⌘K</kbd> o <kbd>Ctrl+K</kbd> para abrir Smart Search. Busque conversaciones y mensajes o elija una acción rápida disponible. Seleccione un resultado para abrirlo. Desde el menú de cuenta, al final de la barra lateral, elija <strong>All Workspaces</strong> para ver los espacios disponibles para su cuenta.</p>
                  HTML
                },
                fr: {
                  title: "Navigation et Palette de Commandes (⌘K)",
                  content: <<~HTML
                    <p>Appuyez sur <kbd>⌘K</kbd> ou <kbd>Ctrl+K</kbd> pour ouvrir Smart Search. Recherchez des conversations et des messages ou choisissez une action rapide disponible. Sélectionnez un résultat pour l'ouvrir. Dans le menu du compte, en bas de la barre latérale, choisissez <strong>All Workspaces</strong> pour afficher les espaces accessibles à votre compte.</p>
                  HTML
                },
                "pt-BR": {
                  title: "Navegação e Paleta de Comandos (⌘K)",
                  content: <<~HTML
                    <p>Pressione <kbd>⌘K</kbd> ou <kbd>Ctrl+K</kbd> para abrir o Smart Search. Pesquise conversas e mensagens ou escolha uma ação rápida disponível. Selecione um resultado para abri-lo. No menu da conta, na parte inferior da barra lateral, escolha <strong>All Workspaces</strong> para ver os espaços disponíveis para sua conta.</p>
                  HTML
                },
                ar: {
                  title: "التنقل ولوحة الأوامر السريعة (⌘K)",
                  content: <<~HTML
                    <p>اضغط على <kbd>⌘K</kbd> أو <kbd>Ctrl+K</kbd> لفتح Smart Search. ابحث عن المحادثات والرسائل أو اختر إجراءً سريعًا متاحًا، ثم حدد النتيجة لفتحها. من قائمة الحساب أسفل الشريط الجانبي، اختر <strong>All Workspaces</strong> لعرض مساحات العمل المتاحة لحسابك.</p>
                  HTML
                },
                ko: {
                  title: "워크스페이스 탐색 및 커맨드 팔레트 (⌘K)",
                  content: <<~HTML
                    <p><kbd>⌘K</kbd> 또는 <kbd>Ctrl+K</kbd>를 눌러 Smart Search를 여세요. 대화와 메시지를 검색하거나 사용 가능한 빠른 작업을 선택할 수 있습니다. 결과를 선택하면 해당 항목이나 작업이 열립니다. 사이드바 아래쪽의 계정 메뉴에서 <strong>All Workspaces</strong>를 선택하면 계정에서 사용할 수 있는 워크스페이스를 볼 수 있습니다.</p>
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
