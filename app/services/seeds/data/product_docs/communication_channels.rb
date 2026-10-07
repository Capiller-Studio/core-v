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
                description: "Set up Email, Web Widget, Contact Form, Facebook, Instagram, WhatsApp, and Custom channels."
              },
              de: {
                name: "Kommunikationskanäle",
                description: "Richten Sie E-Mail-, Web-Widget-, Kontaktformular-, Facebook-, Instagram-, WhatsApp- und benutzerdefinierte Kanäle ein."
              },
              es: {
                name: "Canales de Comunicación",
                description: "Configure canales de correo, Web Widget, formulario de contacto, Facebook, Instagram, WhatsApp y canales personalizados."
              },
              fr: {
                name: "Canaux de Communication",
                description: "Configurez les canaux e-mail, Web Widget, formulaire de contact, Facebook, Instagram, WhatsApp et les canaux personnalisés."
              },
              "pt-BR": {
                name: "Canais de Atendimento",
                description: "Configure canais de e-mail, Web Widget, formulário de contato, Facebook, Instagram, WhatsApp e canais personalizados."
              },
              ar: {
                name: "قنوات الاتصال والدعم",
                description: "أعد قنوات البريد الإلكتروني وWeb Widget ونموذج الاتصال وFacebook وInstagram وWhatsApp والقنوات المخصصة."
              },
              ko: {
                name: "상담 채널 연동",
                description: "이메일, Web Widget, 문의 양식, Facebook, Instagram, WhatsApp 및 사용자 지정 채널을 설정합니다."
              }
            },
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
                    <p>An Email channel can receive forwarded support mail and can optionally use your mail provider's SMTP and IMAP settings. Configure it from the Email Channels area; the generated forwarding address and provider instructions are shown on the saved channel.</p>
                    <h3>Create an Email channel</h3>
                    <ol>
                      <li>Open <strong>Settings &rarr; Channels &rarr; Email Channels</strong> and add a channel.</li>
                      <li>Enter the support email address and a channel name, then save.</li>
                      <li>Open the saved channel and copy its generated forwarding address.</li>
                    </ol>
                    <h3>Forward incoming mail</h3>
                    <ol>
                      <li>In your email provider, create a forwarding rule from the support address to the Deskbolic forwarding address.</li>
                      <li>Follow the provider-specific instructions shown on the channel page.</li>
                      <li>Use the channel's verification action, then send a message to the support address and confirm that it appears in the Deskbolic inbox.</li>
                    </ol>
                    <h3>Configure outgoing or mailbox access</h3>
                    <p>If your setup uses a custom mail server, expand the SMTP and/or IMAP sections on the channel edit page, enable the needed connection, enter the credentials from your mail provider, and use the available connection test. Provider settings vary; use the host, ports, and security options supplied by your mail administrator.</p>
                  HTML
                },
                de: {
                  title: "E-Mail-Kanäle & Weiterleitung einrichten",
                  content: "<p>Ein E-Mail-Kanal empfängt weitergeleitete Supportnachrichten und kann optional SMTP/IMAP Ihres Anbieters verwenden. Die erzeugte Weiterleitungsadresse finden Sie nach dem Speichern im Kanal.</p><h3>E-Mail-Kanal anlegen</h3><ol><li>Öffnen Sie <strong>Settings → Channels → Email Channels</strong> und fügen Sie einen Kanal hinzu.</li><li>Geben Sie die Supportadresse und einen Kanalnamen ein und speichern Sie.</li><li>Öffnen Sie den Kanal und kopieren Sie die erzeugte Weiterleitungsadresse.</li></ol><h3>Eingehende Nachrichten weiterleiten</h3><ol><li>Erstellen Sie bei Ihrem E-Mail-Anbieter eine Weiterleitungsregel von der Supportadresse zur Deskbolic-Adresse.</li><li>Folgen Sie den anbieterbezogenen Hinweisen auf der Kanalseite.</li><li>Verifizieren Sie den Kanal, senden Sie eine Testnachricht und prüfen Sie den Eingang im Deskbolic-Postfach.</li></ol><h3>SMTP/IMAP verbinden</h3><p>Wenn Sie einen eigenen Mailserver verwenden, öffnen Sie im Kanal die SMTP- und/oder IMAP-Einstellungen, aktivieren Sie die benötigte Verbindung, geben Sie die Zugangsdaten Ihres Anbieters ein und führen Sie den angebotenen Verbindungstest aus. Host, Ports und Sicherheitseinstellungen erhalten Sie von Ihrer Mailadministration.</p>"
                },
                es: {
                  title: "Configuración de Canales de Correo Electrónico",
                  content: "<p>Un canal de correo puede recibir mensajes reenviados y usar opcionalmente SMTP/IMAP de su proveedor. La dirección de reenvío generada aparece después de guardar el canal.</p><h3>Crear el canal</h3><ol><li>Abra <strong>Settings → Channels → Email Channels</strong> y añada un canal.</li><li>Introduzca la dirección de soporte y un nombre para el canal; guarde.</li><li>Abra el canal guardado y copie la dirección de reenvío generada.</li></ol><h3>Reenviar mensajes entrantes</h3><ol><li>Cree en su proveedor una regla que reenvíe los mensajes de soporte a la dirección de Deskbolic.</li><li>Siga las instrucciones específicas del proveedor que aparecen en la página del canal.</li><li>Verifique el canal, envíe un mensaje de prueba y confirme que llega a la bandeja de Deskbolic.</li></ol><h3>Conectar SMTP/IMAP</h3><p>Si utiliza un servidor propio, abra la sección SMTP o IMAP en la edición del canal, active la conexión necesaria, introduzca las credenciales del proveedor y use la prueba disponible. Solicite host, puertos y seguridad a su administrador de correo.</p>"
                },
                fr: {
                  title: "Configuration des Canaux E-mail",
                  content: "<p>Un canal e-mail reçoit les messages transférés et peut utiliser les paramètres SMTP/IMAP de votre fournisseur. L'adresse de transfert générée s'affiche après l'enregistrement.</p><h3>Créer un canal e-mail</h3><ol><li>Ouvrez <strong>Settings → Channels → Email Channels</strong> et ajoutez un canal.</li><li>Saisissez l'adresse de support et un nom, puis enregistrez.</li><li>Ouvrez le canal enregistré et copiez l'adresse de transfert générée.</li></ol><h3>Transférer les messages entrants</h3><ol><li>Créez chez votre fournisseur une règle de transfert de l'adresse support vers l'adresse Deskbolic.</li><li>Suivez les consignes propres au fournisseur indiquées sur la page du canal.</li><li>Vérifiez le canal, envoyez un message test et confirmez sa réception dans la boîte Deskbolic.</li></ol><h3>Connecter SMTP/IMAP</h3><p>Avec un serveur personnalisé, ouvrez les sections SMTP et/ou IMAP de la page de modification, activez la connexion voulue, saisissez les identifiants du fournisseur et lancez le test proposé. Demandez le serveur, les ports et la sécurité à votre administrateur e-mail.</p>"
                },
                "pt-BR": {
                  title: "Configuração de Canais de E-mail",
                  content: "<p>Um canal de e-mail recebe mensagens encaminhadas e pode usar SMTP/IMAP do provedor. O endereço de encaminhamento gerado aparece após salvar o canal.</p><h3>Criar um canal</h3><ol><li>Abra <strong>Settings → Channels → Email Channels</strong> e adicione um canal.</li><li>Informe o endereço de suporte e um nome para o canal; salve.</li><li>Abra o canal salvo e copie o endereço de encaminhamento gerado.</li></ol><h3>Encaminhar mensagens recebidas</h3><ol><li>No provedor de e-mail, crie uma regra que encaminhe as mensagens de suporte para o endereço Deskbolic.</li><li>Siga as instruções específicas do provedor exibidas na página do canal.</li><li>Verifique o canal, envie uma mensagem de teste e confirme o recebimento na caixa Deskbolic.</li></ol><h3>Conectar SMTP/IMAP</h3><p>Se usar um servidor próprio, abra as seções SMTP e/ou IMAP na edição do canal, ative a conexão necessária, informe as credenciais do provedor e execute o teste disponível. Consulte o administrador de e-mail para host, portas e segurança.</p>"
                },
                ar: {
                  title: "إعداد قنوات البريد الإلكتروني وإعادة التوجيه",
                  content: "<p>تستقبل قناة البريد الرسائل المُعاد توجيهها ويمكنها استخدام إعدادات SMTP/IMAP لمزودك. يظهر عنوان إعادة التوجيه بعد حفظ القناة.</p><h3>إنشاء قناة بريد</h3><ol><li>افتح <strong>Settings → Channels → Email Channels</strong> وأضف قناة.</li><li>أدخل عنوان الدعم واسمًا للقناة ثم احفظ.</li><li>افتح القناة المحفوظة وانسخ عنوان إعادة التوجيه الذي أنشأه Deskbolic.</li></ol><h3>إعادة توجيه البريد الوارد</h3><ol><li>أنشئ لدى مزود البريد قاعدة لتحويل الرسائل من عنوان الدعم إلى عنوان Deskbolic.</li><li>اتبع تعليمات المزود الظاهرة في صفحة القناة.</li><li>تحقق من القناة وأرسل رسالة اختبار وتأكد من ظهورها في صندوق وارد Deskbolic.</li></ol><h3>الاتصال عبر SMTP/IMAP</h3><p>إذا كنت تستخدم خادم بريد خاصًا، افتح إعدادات SMTP و/أو IMAP في تعديل القناة، وفعّل الاتصال المطلوب، وأدخل بيانات المزود وشغّل الاختبار المتاح. اطلب اسم المضيف والمنافذ وإعدادات الأمان من مسؤول البريد.</p>"
                },
                ko: {
                  title: "이메일 채널 및 자동 전달 설정",
                  content: "<p>이메일 채널은 전달된 지원 메일을 받을 수 있고, 선택적으로 이메일 공급자의 SMTP/IMAP 설정을 사용할 수 있습니다. 채널 저장 후 생성된 전달 주소가 표시됩니다.</p><h3>이메일 채널 만들기</h3><ol><li><strong>Settings → Channels → Email Channels</strong>를 열고 채널을 추가합니다.</li><li>지원 이메일 주소와 채널 이름을 입력하고 저장합니다.</li><li>저장한 채널을 열고 생성된 전달 주소를 복사합니다.</li></ol><h3>수신 메일 전달</h3><ol><li>이메일 공급자에서 지원 주소의 메일을 Deskbolic 전달 주소로 보내는 규칙을 만듭니다.</li><li>채널 페이지에 표시되는 공급자별 안내를 따릅니다.</li><li>채널을 인증하고 테스트 메일을 보내 Deskbolic 받은 편지함에 도착하는지 확인합니다.</li></ol><h3>SMTP/IMAP 연결</h3><p>자체 메일 서버를 사용한다면 채널 편집 화면에서 SMTP 및/또는 IMAP 설정을 열고 필요한 연결을 활성화합니다. 공급자 자격 증명을 입력하고 연결 테스트를 실행하세요. 호스트, 포트, 보안 설정은 메일 관리자에게 확인합니다.</p>"
                }
              }
            },
            {
              key: :web_widget_installation,
              position: 2,
              translations: {
                en: {
                  title: "Create, Configure, and Install the Web Widget",
                  content: <<~HTML
                    <p>Each Web Widget channel has its own installation code. Copy the generated snippet from the channel's edit page so it contains the correct account and widget identifiers.</p>
                    <h3>Create and configure the channel</h3>
                    <ol>
                      <li>Open <strong>Settings &rarr; Channels &rarr; Web Widget Channels</strong> and create a channel.</li>
                      <li>Set a recognizable channel name, add every website hostname allowed to load the widget, and choose its default language.</li>
                      <li>Save the channel, then open its edit page. Under <strong>Inbox Settings</strong>, review collaborators, teams, auto-assignment, business hours, SLAs, and the AI settings available to your workspace.</li>
                      <li>Under <strong>Appearance &amp; Branding</strong>, choose the theme color and launcher position. Custom branding, logos, launcher icons, and footer text may depend on your plan.</li>
                      <li>Under <strong>Module Integrations</strong>, optionally link a Help Center, enable it in the widget, select a pre-chat form, choose a Web Widget AI Agent, and set an email fallback channel.</li>
                      <li>Under <strong>Widget Behaviors</strong>, decide whether to allow anonymous conversations and whether to enforce secure identity.</li>
                      <li>Use <strong>Translations</strong> to configure the widget's customer-facing text for additional supported languages.</li>
                    </ol>
                    <h3>Install the generated snippet</h3>
                    <ol>
                      <li>Copy the generated <strong>Standard HTML</strong> snippet. Use the provided React or Next.js example for those frameworks. Keep the exact account and channel identifiers in the generated code.</li>
                      <li>Add the snippet to the website page where the widget should load, following the placement instructions in the channel editor. Deploy the change.</li>
                      <li>Open the deployed page from a hostname in the allowed-host list, start a conversation, and verify that it appears in the expected Deskbolic inbox. Test a reply as well.</li>
                    </ol>
                    <h3>Troubleshoot the widget</h3>
                    <ul>
                      <li><strong>Widget is missing:</strong> confirm the page uses the complete snippet copied from this channel, the script is deployed, and the current hostname is allowed.</li>
                      <li><strong>Widget loads on one site but not another:</strong> add the other site's hostname to Allowed Hosts, save, and reload the deployed page.</li>
                      <li><strong>Conversation goes to an unexpected place:</strong> review the channel's inbox assignment, auto-assignment, collaborators, and business-hours settings.</li>
                      <li><strong>Help Center, pre-chat, or fallback isn't offered:</strong> verify the corresponding integration is selected and enabled in this channel's settings.</li>
                    </ul>
                  HTML
                },
                de: {
                  title: "Web-Chat-Widget Installation & Design",
                  content: "<p>Jeder Web-Widget-Kanal hat einen eigenen Installationscode. Kopieren Sie den vollständigen generierten Code aus der Bearbeitungsseite, damit Konto- und Widget-IDs stimmen.</p><h3>Kanal einrichten</h3><ol><li>Öffnen Sie <strong>Settings → Channels → Web Widget Channels</strong> und erstellen Sie einen Kanal.</li><li>Geben Sie einen Namen ein, tragen Sie alle Website-Hosts unter Allowed Hosts ein und wählen Sie die Standardsprache.</li><li>Speichern Sie den Kanal. Prüfen Sie unter <strong>Inbox Settings</strong> Mitwirkende, Teams, automatische Zuweisung, Geschäftszeiten, SLA und verfügbare KI-Einstellungen.</li><li>Konfigurieren Sie unter <strong>Appearance &amp; Branding</strong> Farbe und Position. Branding-Optionen können vom Tarif abhängen.</li><li>Wählen Sie unter <strong>Module Integrations</strong> optional Help Center, Pre-Chat-Formular, Web-Widget-AI-Agent und E-Mail-Fallback.</li><li>Prüfen Sie unter <strong>Widget Behaviors</strong> anonyme Gespräche und sichere Identität. Übersetzen Sie Kundentexte unter <strong>Translations</strong>.</li></ol><h3>Code installieren und testen</h3><ol><li>Kopieren Sie <strong>Standard HTML</strong> oder das bereitgestellte React-/Next.js-Beispiel. Ändern Sie Konto- und Kanal-IDs nicht.</li><li>Fügen Sie den Code gemäß Platzierungshinweis auf der Website ein und veröffentlichen Sie die Änderung.</li><li>Öffnen Sie eine erlaubte Domain, starten Sie ein Testgespräch und prüfen Sie Eingang und Antwort im richtigen Postfach.</li></ol><h3>Fehlerbehebung</h3><ul><li>Widget fehlt: vollständigen Code, Deployment und aktuellen Host in Allowed Hosts prüfen.</li><li>Widget fehlt nur auf einer Domain: diesen Host ergänzen, speichern und Seite neu laden.</li><li>Gespräch landet falsch: Postfachzuweisung, automatische Zuweisung, Mitwirkende und Geschäftszeiten prüfen.</li><li>Help Center oder Pre-Chat fehlt: Integration im Kanal auswählen und aktivieren.</li></ul>"
                },
                es: {
                  title: "Instalación del Widget de Chat Web",
                  content: "<p>Cada canal Web Widget tiene su propio código. Copie el fragmento completo de la edición del canal para conservar los identificadores correctos de cuenta y widget.</p><h3>Crear y configurar el canal</h3><ol><li>Abra <strong>Settings → Channels → Web Widget Channels</strong> y cree un canal.</li><li>Asigne un nombre, añada todos los hosts del sitio a Allowed Hosts y elija el idioma predeterminado.</li><li>Guarde y revise en <strong>Inbox Settings</strong> los colaboradores, equipos, asignación automática, horario comercial, SLA y opciones de IA disponibles.</li><li>En <strong>Appearance &amp; Branding</strong>, elija color y posición. Algunas opciones de marca pueden depender del plan.</li><li>En <strong>Module Integrations</strong>, configure si lo necesita el Help Center, el formulario previo al chat, el agente de IA de Web Widget y el canal de respaldo por correo.</li><li>En <strong>Widget Behaviors</strong>, configure conversaciones anónimas e identidad segura. Traduce los textos del widget desde <strong>Translations</strong>.</li></ol><h3>Instalar y comprobar</h3><ol><li>Copie <strong>Standard HTML</strong> o el ejemplo para React/Next.js. Mantenga los identificadores generados.</li><li>Inserte el código en la página indicada y publique el cambio.</li><li>Abra el sitio desde un host permitido, inicie una conversación de prueba y compruebe su bandeja y respuesta.</li></ol><h3>Solución de problemas</h3><ul><li>Si no aparece, revise el código completo, el despliegue y el host permitido.</li><li>Si falla en un dominio concreto, añádalo a Allowed Hosts, guarde y recargue.</li><li>Si llega a otra bandeja, revise asignación, colaboradores, equipos y horario comercial.</li><li>Si faltan Help Center o pre-chat, compruebe que la integración esté seleccionada y activada.</li></ul>"
                },
                fr: {
                  title: "Installation du Widget de Chat Web",
                  content: "<p>Chaque canal Web Widget possède son propre code d'installation. Copiez le code complet depuis la page du canal pour conserver les identifiants du compte et du widget.</p><h3>Créer et configurer le canal</h3><ol><li>Ouvrez <strong>Settings → Channels → Web Widget Channels</strong> et créez un canal.</li><li>Nommez-le, ajoutez tous les hôtes du site à Allowed Hosts et choisissez la langue par défaut.</li><li>Enregistrez puis vérifiez dans <strong>Inbox Settings</strong> les collaborateurs, équipes, l'attribution automatique, les horaires ouvrés, SLA et options IA disponibles.</li><li>Dans <strong>Appearance &amp; Branding</strong>, choisissez la couleur et la position. Certaines options de marque dépendent du forfait.</li><li>Dans <strong>Module Integrations</strong>, associez si besoin le Help Center, le formulaire pré-chat, un agent IA Web Widget et un canal e-mail de secours.</li><li>Dans <strong>Widget Behaviors</strong>, définissez les conversations anonymes et l'identité sécurisée. Traduisez les textes client dans <strong>Translations</strong>.</li></ol><h3>Installer et tester</h3><ol><li>Copiez <strong>Standard HTML</strong> ou l'exemple React/Next.js fourni sans modifier les identifiants.</li><li>Ajoutez le code à la page indiquée et déployez le site.</li><li>Depuis un hôte autorisé, ouvrez le widget, lancez un test et vérifiez la réception et la réponse dans la bonne boîte.</li></ol><h3>Dépannage</h3><ul><li>Widget absent : vérifiez le code complet, le déploiement et l'hôte autorisé.</li><li>Absent sur un seul domaine : ajoutez son hôte à Allowed Hosts, enregistrez et rechargez.</li><li>Conversation dans la mauvaise boîte : vérifiez l'attribution, les collaborateurs, équipes et horaires.</li><li>Help Center ou pré-chat absent : vérifiez que l'intégration est sélectionnée et activée.</li></ul>"
                },
                "pt-BR": {
                  title: "Instalação do Widget de Chat Web",
                  content: "<p>Cada canal Web Widget tem seu próprio código de instalação. Copie o trecho completo na edição do canal para manter os identificadores corretos da conta e do widget.</p><h3>Criar e configurar o canal</h3><ol><li>Abra <strong>Settings → Channels → Web Widget Channels</strong> e crie um canal.</li><li>Defina um nome, adicione todos os hosts do site em Allowed Hosts e escolha o idioma padrão.</li><li>Salve e revise em <strong>Inbox Settings</strong> colaboradores, equipes, atribuição automática, horário comercial, SLA e opções de IA disponíveis.</li><li>Em <strong>Appearance &amp; Branding</strong>, escolha cor e posição. Algumas opções de marca dependem do plano.</li><li>Em <strong>Module Integrations</strong>, configure se necessário Help Center, formulário pré-chat, agente de IA Web Widget e canal de e-mail alternativo.</li><li>Em <strong>Widget Behaviors</strong>, defina conversas anônimas e identidade segura. Traduza os textos do widget em <strong>Translations</strong>.</li></ol><h3>Instalar e testar</h3><ol><li>Copie <strong>Standard HTML</strong> ou o exemplo React/Next.js fornecido; mantenha os identificadores gerados.</li><li>Adicione o código à página indicada e publique a alteração.</li><li>Acesse o site por um host permitido, inicie uma conversa de teste e confira a caixa e a resposta.</li></ol><h3>Resolver problemas</h3><ul><li>Widget ausente: confira o código completo, a publicação e o host permitido.</li><li>Ausente em um domínio: adicione o host em Allowed Hosts, salve e recarregue.</li><li>Conversa na caixa errada: revise atribuição, colaboradores, equipes e horário comercial.</li><li>Help Center ou pré-chat ausente: confirme que a integração está selecionada e ativada.</li></ul>"
                },
                ar: {
                  title: "تثبيت وتخصيص ودجة الدردشة للموقع",
                  content: "<p>لكل قناة Web Widget رمز تثبيت خاص بها. انسخ المقتطف كاملًا من صفحة تعديل القناة للحفاظ على معرّفات الحساب والودجة الصحيحة.</p><h3>إنشاء القناة وإعدادها</h3><ol><li>افتح <strong>Settings → Channels → Web Widget Channels</strong> وأنشئ قناة.</li><li>أدخل اسمًا وأضف جميع أسماء مضيفي الموقع في Allowed Hosts واختر اللغة الافتراضية.</li><li>احفظ وراجع المتعاونين والفرق والتعيين التلقائي وساعات العمل وسياسات SLA وإعدادات الذكاء الاصطناعي المتاحة ضمن <strong>Inbox Settings</strong>.</li><li>اختر اللون والموضع في <strong>Appearance &amp; Branding</strong>. قد تعتمد خيارات العلامة التجارية على خطتك.</li><li>من <strong>Module Integrations</strong> اربط اختياريًا مركز المساعدة ونموذج ما قبل الدردشة ووكيل Web Widget وقناة بريد احتياطية.</li><li>من <strong>Widget Behaviors</strong> اضبط المحادثات المجهولة والهوية الآمنة. ترجم النصوص الموجهة للعملاء في <strong>Translations</strong>.</li></ol><h3>تثبيت الرمز واختباره</h3><ol><li>انسخ <strong>Standard HTML</strong> أو مثال React/Next.js المقدم ولا تغيّر المعرّفات.</li><li>أضف الرمز إلى الصفحة وفق تعليمات الموضع وانشر التغيير.</li><li>افتح الموقع من مضيف مسموح وابدأ محادثة اختبار وتحقق من ظهورها والرد عليها في صندوق الوارد الصحيح.</li></ol><h3>استكشاف الأخطاء</h3><ul><li>إذا لم تظهر الودجة، فتحقق من اكتمال الرمز ونشره والمضيف المسموح.</li><li>إذا غابت عن نطاق واحد، أضف المضيف إلى Allowed Hosts واحفظ وأعد تحميل الصفحة.</li><li>إذا وصلت المحادثة إلى صندوق خاطئ، راجع التعيين والمتعاونين والفرق وساعات العمل.</li><li>إذا لم يظهر مركز المساعدة أو نموذج ما قبل الدردشة، تحقق من تحديد التكامل وتفعيله.</li></ul>"
                },
                ko: {
                  title: "웹 채팅 위젯 설치 및 커스텀 디자인",
                  content: "<p>Web Widget 채널마다 전용 설치 코드가 있습니다. 계정 및 위젯 식별자가 맞도록 채널 편집 화면에서 생성된 전체 코드를 복사하세요.</p><h3>채널 만들기 및 설정</h3><ol><li><strong>Settings → Channels → Web Widget Channels</strong>를 열고 채널을 만듭니다.</li><li>알아보기 쉬운 이름을 입력하고 웹사이트 호스트를 Allowed Hosts에 추가한 뒤 기본 언어를 선택합니다.</li><li>저장한 뒤 <strong>Inbox Settings</strong>에서 협업자, 팀, 자동 할당, 업무 시간, SLA 및 사용 가능한 AI 설정을 검토합니다.</li><li><strong>Appearance &amp; Branding</strong>에서 색상과 런처 위치를 설정합니다. 일부 브랜드 설정은 요금제에 따라 달라질 수 있습니다.</li><li><strong>Module Integrations</strong>에서 필요하면 Help Center, 사전 채팅 양식, Web Widget AI Agent, 이메일 대체 채널을 연결합니다.</li><li><strong>Widget Behaviors</strong>에서 익명 대화와 보안 ID 사용을 설정하고 <strong>Translations</strong>에서 고객 표시 문구를 번역합니다.</li></ol><h3>코드 설치 및 확인</h3><ol><li>생성된 <strong>Standard HTML</strong> 코드 또는 React/Next.js 예제를 복사하고 식별자를 그대로 유지합니다.</li><li>안내된 위치에 코드를 추가하고 사이트를 배포합니다.</li><li>허용된 호스트에서 사이트를 열어 테스트 대화를 시작하고 올바른 받은 편지함 수신 및 답장을 확인합니다.</li></ol><h3>문제 해결</h3><ul><li>위젯이 없으면 전체 코드, 배포 여부, 허용된 호스트를 확인합니다.</li><li>특정 도메인에서만 없으면 해당 호스트를 Allowed Hosts에 추가하고 저장 후 새로고침합니다.</li><li>대화가 다른 받은 편지함에 오면 할당, 협업자, 팀, 업무 시간을 검토합니다.</li><li>Help Center나 사전 채팅이 없으면 해당 통합이 선택되고 활성화되었는지 확인합니다.</li></ul>"
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
                    <p>Deskbolic offers two ways to connect a WhatsApp Business channel: Meta's guided embedded signup flow, or manual setup with credentials from your Meta developer configuration.</p>
                    <h3>Guided setup with Meta</h3>
                    <ol>
                      <li>Open <strong>Settings &rarr; Channels &rarr; WhatsApp</strong> and start adding a channel.</li>
                      <li>Choose the embedded signup option and confirm you can administer the relevant Meta Business Portfolio. Have access to the business phone number so you can complete Meta's verification prompts.</li>
                      <li>Select <strong>Connect with WhatsApp</strong>, sign in to Meta, and follow the prompts to choose or create the business assets and phone number.</li>
                      <li>When Meta returns you to Deskbolic, confirm the channel appears in the channel list, then send a test message.</li>
                    </ol>
                    <h3>Manual setup</h3>
                    <p>If you choose the manual method, use the credentials and identifiers requested by the form from your Meta WhatsApp setup. Enter them in the corresponding fields and save. Keep access tokens private; regenerate them in Meta and update the channel if they are exposed or revoked.</p>
                    <h3>After connecting</h3>
                    <p>Open the channel's edit page to review its inbox settings. Message template synchronization is available from the channel settings. If signup or messaging fails, verify the selected Meta business assets, phone number, access permissions, and channel connection status.</p>
                  HTML
                },
                de: {
                  title: "WhatsApp Business API-Integration",
                  content: "<p>Verbinden Sie WhatsApp Business über die geführte Meta-Registrierung oder manuell mit den Zugangsdaten Ihrer Meta-Konfiguration.</p><h3>Geführte Verbindung</h3><ol><li>Öffnen Sie <strong>Settings → Channels → WhatsApp</strong> und fügen Sie einen Kanal hinzu.</li><li>Wählen Sie die eingebettete Registrierung. Sie benötigen Verwaltungszugriff auf das passende Meta Business Portfolio und die Geschäftsnummer.</li><li>Wählen Sie <strong>Connect with WhatsApp</strong>, melden Sie sich bei Meta an und folgen Sie den Schritten zur Auswahl oder Erstellung der Unternehmensressourcen und Telefonnummer.</li><li>Kehren Sie zu Deskbolic zurück, prüfen Sie den Kanal in der Liste und senden Sie eine Testnachricht.</li></ol><h3>Manuelle Verbindung und Prüfung</h3><p>Bei manueller Einrichtung tragen Sie die im Formular geforderten Werte aus Ihrer Meta-WhatsApp-Konfiguration ein und speichern. Halten Sie Zugriffstoken geheim und aktualisieren Sie sie in Deskbolic, wenn sie offengelegt oder widerrufen wurden. Prüfen Sie danach Postfacheinstellungen und synchronisieren Sie Nachrichtenvorlagen in den Kanaleinstellungen. Bei Fehlern kontrollieren Sie Meta-Ressourcen, Telefonnummer, Berechtigungen und Verbindungsstatus.</p>"
                },
                es: {
                  title: "Integración de WhatsApp Business API",
                  content: "<p>Conecte WhatsApp Business mediante el registro guiado de Meta o una configuración manual con las credenciales de su configuración de Meta.</p><h3>Conexión guiada</h3><ol><li>Abra <strong>Settings → Channels → WhatsApp</strong> y añada un canal.</li><li>Elija el registro integrado. Necesita acceso de administración al Meta Business Portfolio correspondiente y al número de empresa.</li><li>Seleccione <strong>Connect with WhatsApp</strong>, inicie sesión en Meta y siga los pasos para elegir o crear los activos y el número de teléfono.</li><li>Vuelva a Deskbolic, confirme que aparece el canal y envíe un mensaje de prueba.</li></ol><h3>Configuración manual y comprobaciones</h3><p>Para el método manual, introduzca los datos que solicita el formulario desde su configuración de WhatsApp en Meta y guarde. Mantenga privados los tokens; actualícelos en Deskbolic si se exponen o revocan. Después, revise los ajustes de la bandeja y sincronice las plantillas desde el canal. Si falla, compruebe los activos de Meta, el número, los permisos y el estado de conexión.</p>"
                },
                fr: {
                  title: "Intégration de l'API WhatsApp Business",
                  content: "<p>Connectez WhatsApp Business avec l'inscription guidée de Meta ou une configuration manuelle à l'aide des identifiants de votre configuration Meta.</p><h3>Connexion guidée</h3><ol><li>Ouvrez <strong>Settings → Channels → WhatsApp</strong> et ajoutez un canal.</li><li>Choisissez l'inscription intégrée. Vous devez administrer le Meta Business Portfolio concerné et avoir accès au numéro professionnel.</li><li>Sélectionnez <strong>Connect with WhatsApp</strong>, connectez-vous à Meta et suivez les étapes de choix ou de création des ressources et du numéro.</li><li>Revenez dans Deskbolic, vérifiez que le canal apparaît et envoyez un message test.</li></ol><h3>Configuration manuelle et vérification</h3><p>Avec la méthode manuelle, saisissez les valeurs demandées par le formulaire depuis la configuration WhatsApp Meta, puis enregistrez. Gardez les jetons privés et remplacez-les dans Deskbolic s'ils sont exposés ou révoqués. Vérifiez ensuite les paramètres de la boîte et synchronisez les modèles depuis les paramètres du canal. En cas d'échec, vérifiez les ressources Meta, le numéro, les autorisations et l'état de connexion.</p>"
                },
                "pt-BR": {
                  title: "Integração do WhatsApp Business API",
                  content: "<p>Conecte o WhatsApp Business pelo cadastro guiado da Meta ou pela configuração manual com as credenciais da sua configuração Meta.</p><h3>Conexão guiada</h3><ol><li>Abra <strong>Settings → Channels → WhatsApp</strong> e adicione um canal.</li><li>Escolha o cadastro integrado. Você precisa administrar o Meta Business Portfolio correspondente e ter acesso ao número comercial.</li><li>Selecione <strong>Connect with WhatsApp</strong>, entre na Meta e siga as etapas para escolher ou criar os ativos empresariais e o número.</li><li>Volte ao Deskbolic, confirme o canal na lista e envie uma mensagem de teste.</li></ol><h3>Configuração manual e verificações</h3><p>No método manual, preencha os dados solicitados pelo formulário usando sua configuração do WhatsApp na Meta e salve. Mantenha tokens privados e atualize-os no Deskbolic se forem expostos ou revogados. Revise os ajustes da caixa e sincronize modelos nas configurações do canal. Se houver falha, confira os ativos Meta, o número, as permissões e o status da conexão.</p>"
                },
                ar: {
                  title: "التكامل مع WhatsApp Business API",
                  content: "<p>اربط WhatsApp Business عبر التسجيل الموجّه من Meta أو الإعداد اليدوي باستخدام بيانات تكوين Meta لديك.</p><h3>الربط الموجّه</h3><ol><li>افتح <strong>Settings → Channels → WhatsApp</strong> وأضف قناة.</li><li>اختر التسجيل المضمّن. تحتاج إلى صلاحية إدارة Meta Business Portfolio المناسب والوصول إلى رقم الشركة.</li><li>اختر <strong>Connect with WhatsApp</strong> وسجّل الدخول إلى Meta واتبع خطوات اختيار أو إنشاء أصول النشاط التجاري ورقم الهاتف.</li><li>عد إلى Deskbolic وتحقق من ظهور القناة ثم أرسل رسالة اختبار.</li></ol><h3>الإعداد اليدوي والتحقق</h3><p>للطريقة اليدوية أدخل القيم التي يطلبها النموذج من إعداد WhatsApp في Meta ثم احفظ. أبقِ رموز الوصول سرية وحدّثها في Deskbolic إذا كُشفت أو أُلغيت. راجع إعدادات صندوق الوارد وزامن قوالب الرسائل من إعدادات القناة. عند الفشل تحقق من أصول Meta والرقم والأذونات وحالة الاتصال.</p>"
                },
                ko: {
                  title: "WhatsApp 비즈니스 API 연동",
                  content: "<p>Meta의 안내형 가입 절차 또는 Meta 설정 자격 증명을 사용한 수동 방식으로 WhatsApp Business를 연결할 수 있습니다.</p><h3>안내형 연결</h3><ol><li><strong>Settings → Channels → WhatsApp</strong>를 열고 채널 추가를 시작합니다.</li><li>임베디드 가입을 선택합니다. 해당 Meta Business Portfolio 관리 권한과 비즈니스 전화번호 접근 권한이 필요합니다.</li><li><strong>Connect with WhatsApp</strong>을 선택하고 Meta에 로그인한 뒤 비즈니스 자산과 전화번호를 선택하거나 만드는 단계를 진행합니다.</li><li>Deskbolic으로 돌아와 채널 목록에 표시되는지 확인하고 테스트 메시지를 보냅니다.</li></ol><h3>수동 설정 및 연결 확인</h3><p>수동 방식은 Meta WhatsApp 설정에서 양식이 요구하는 자격 증명과 식별자를 입력해 저장합니다. 액세스 토큰을 비공개로 보관하고 노출 또는 취소되면 Meta에서 재발급해 Deskbolic도 업데이트하세요. 채널 받은 편지함 설정을 검토하고 메시지 템플릿 동기화도 확인합니다. 문제가 있으면 Meta 자산, 전화번호, 권한과 연결 상태를 점검하세요.</p>"
                }
              }
            },
            {
              key: :facebook_messenger_setup,
              position: 4,
              translations: {
                en: {
                  title: "Connect a Facebook Page to Messenger",
                  content: <<~HTML
                    <p>Connect a Facebook Page to receive and reply to its Messenger conversations from Deskbolic. The person connecting the Page must be able to access it and approve the permissions requested during authorization.</p>
                    <ol>
                      <li>Open <strong>Settings &rarr; Channels &rarr; Facebook</strong>, choose <strong>Connect with Facebook</strong>, then select <strong>Continue with Facebook</strong>.</li>
                      <li>Sign in to the Facebook account that can manage the intended Page. Review and grant the permissions shown by Facebook.</li>
                      <li>When Deskbolic displays the Pages available to connect, select the correct Page and finish setup.</li>
                      <li>Open the new channel's edit page, give it a clear name, and review its inbox settings. Save your changes.</li>
                      <li>Send a Messenger test from a separate account. Confirm the conversation appears in the intended inbox and that an agent reply reaches Messenger.</li>
                    </ol>
                    <h3>Troubleshoot Facebook connection</h3>
                    <ul>
                      <li>If the Page is not listed, check that the signed-in Facebook account has access to it and repeat authorization with the requested permissions enabled.</li>
                      <li>If messages do not arrive or replies fail, confirm the correct Page was selected, check the channel's connection status, and reconnect to refresh authorization if needed.</li>
                      <li>If messages arrive in the wrong inbox, review the channel's inbox settings and collaborator/team assignment.</li>
                    </ul>
                  HTML
                },
                de: { title: "Facebook-Seite mit Messenger verbinden", content: "<p>Verbinden Sie eine Facebook-Seite, damit Ihr Team Messenger-Gespräche in Deskbolic bearbeiten kann. Das Facebook-Konto für die Einrichtung muss Zugriff auf die Seite haben.</p><ol><li>Öffnen Sie <strong>Settings &rarr; Channels &rarr; Facebook</strong> und wählen Sie <strong>Connect with Facebook</strong>, danach <strong>Continue with Facebook</strong>.</li><li>Melden Sie sich beim Konto mit Seitenzugriff an und prüfen Sie die von Facebook angezeigten Berechtigungen. Erteilen Sie die erforderlichen Freigaben.</li><li>Wählen Sie die gewünschte Seite aus der Liste aus und schließen Sie die Verbindung ab.</li><li>Öffnen Sie die Kanalbearbeitung, vergeben Sie einen verständlichen Namen, prüfen Sie die Postfach- und Zuweisungseinstellungen und speichern Sie.</li><li>Senden Sie von einem anderen Facebook-Konto eine Testnachricht. Prüfen Sie den Eingang im richtigen Postfach und senden Sie eine Antwort.</li></ol><p>Fehlt die Seite, prüfen Sie Konto und Berechtigungen und wiederholen Sie die Autorisierung. Bei ausbleibenden Nachrichten oder Antworten kontrollieren Sie den Verbindungsstatus und verbinden Sie die Seite gegebenenfalls erneut. Prüfen Sie bei falschem Postfach dessen Team- und Mitarbeiterzuweisungen.</p>" },
                es: { title: "Conectar una página de Facebook a Messenger", content: "<p>Conecte una página para que el equipo pueda atender sus conversaciones de Messenger en Deskbolic. La cuenta usada para autorizar debe tener acceso a esa página.</p><ol><li>Abra <strong>Settings &rarr; Channels &rarr; Facebook</strong> y elija <strong>Connect with Facebook</strong> y después <strong>Continue with Facebook</strong>.</li><li>Acceda con la cuenta que administra la página y revise los permisos mostrados por Facebook. Concédalos para continuar.</li><li>Seleccione la página correcta en la lista y termine la conexión.</li><li>Abra la edición del canal, asigne un nombre claro, revise la bandeja y los ajustes de asignación y guarde.</li><li>Desde otra cuenta de Facebook, envíe un mensaje de prueba. Confirme que llega a la bandeja correcta y pruebe una respuesta.</li></ol><p>Si la página no aparece, revise el acceso de la cuenta y los permisos y vuelva a autorizar. Si no llegan mensajes o respuestas, compruebe el estado de conexión y reconecte si hace falta. Si llegan a otra bandeja, revise sus equipos y colaboradores.</p>" },
                fr: { title: "Connecter une page Facebook à Messenger", content: "<p>Connectez une page pour traiter ses conversations Messenger dans Deskbolic. Le compte Facebook utilisé pour l'autorisation doit avoir accès à cette page.</p><ol><li>Ouvrez <strong>Settings &rarr; Channels &rarr; Facebook</strong>, choisissez <strong>Connect with Facebook</strong>, puis <strong>Continue with Facebook</strong>.</li><li>Connectez-vous avec le compte qui gère la page et examinez les autorisations affichées par Facebook. Accordez les accès requis.</li><li>Sélectionnez la bonne page dans la liste pour terminer la connexion.</li><li>Ouvrez la modification du canal, donnez-lui un nom explicite, vérifiez la boîte et les paramètres d'attribution, puis enregistrez.</li><li>Depuis un autre compte Facebook, envoyez un message test. Vérifiez sa réception dans la bonne boîte et testez une réponse.</li></ol><p>Si la page est absente, vérifiez l'accès du compte et les autorisations puis recommencez. Si les messages ou réponses n'arrivent pas, contrôlez l'état de connexion et reconnectez la page si nécessaire. Pour une mauvaise boîte, vérifiez les équipes et collègues affectés.</p>" },
                "pt-BR": { title: "Conectar uma página do Facebook ao Messenger", content: "<p>Conecte uma página para que a equipe atenda às conversas do Messenger no Deskbolic. A conta usada na autorização precisa ter acesso à página.</p><ol><li>Abra <strong>Settings &rarr; Channels &rarr; Facebook</strong>, escolha <strong>Connect with Facebook</strong> e depois <strong>Continue with Facebook</strong>.</li><li>Entre com a conta que administra a página e revise as permissões exibidas pelo Facebook. Conceda os acessos necessários.</li><li>Selecione a página correta na lista e conclua a conexão.</li><li>Abra a edição do canal, defina um nome claro, confira a caixa e as configurações de atribuição e salve.</li><li>De outra conta do Facebook, envie uma mensagem de teste. Confirme o recebimento na caixa correta e teste uma resposta.</li></ol><p>Se a página não aparecer, confira o acesso da conta e as permissões e autorize novamente. Se mensagens ou respostas não funcionarem, verifique o status da conexão e reconecte se necessário. Se chegarem à caixa errada, revise equipes e colaboradores configurados nela.</p>" },
                ar: { title: "ربط صفحة Facebook بـ Messenger", content: "<p>اربط صفحة Facebook حتى يتمكن الفريق من إدارة محادثات Messenger في Deskbolic. يجب أن يملك حساب Facebook المستخدم في التفويض صلاحية الوصول إلى الصفحة.</p><ol><li>افتح <strong>Settings &rarr; Channels &rarr; Facebook</strong> واختر <strong>Connect with Facebook</strong> ثم <strong>Continue with Facebook</strong>.</li><li>سجّل الدخول بالحساب الذي يدير الصفحة وراجع الأذونات المعروضة من Facebook وامنح المطلوب.</li><li>اختر الصفحة الصحيحة من القائمة وأكمل الربط.</li><li>افتح تعديل القناة، واكتب اسمًا واضحًا، وراجع إعدادات صندوق الوارد والتعيين ثم احفظ.</li><li>أرسل رسالة اختبار من حساب Facebook آخر. تحقق من وصولها إلى الصندوق الصحيح واختبر إرسال رد.</li></ol><p>إذا لم تظهر الصفحة، فتحقق من صلاحية الحساب والأذونات ثم أعد التفويض. إذا لم تصل الرسائل أو الردود، راجع حالة الاتصال وأعد الربط عند الحاجة. وإذا وصلت إلى صندوق خاطئ، فراجع الفرق والزملاء المحددين فيه.</p>" },
                ko: { title: "Facebook 페이지를 Messenger에 연결", content: "<p>Facebook 페이지를 연결하면 Deskbolic에서 Messenger 대화를 처리할 수 있습니다. 연결에 사용하는 Facebook 계정은 해당 페이지에 접근할 수 있어야 합니다.</p><ol><li><strong>Settings &rarr; Channels &rarr; Facebook</strong>에서 <strong>Connect with Facebook</strong>을 선택한 뒤 <strong>Continue with Facebook</strong>을 누릅니다.</li><li>페이지를 관리하는 계정으로 로그인하고 Facebook이 표시하는 권한을 확인한 후 필요한 권한을 허용합니다.</li><li>목록에서 올바른 페이지를 선택해 연결을 마칩니다.</li><li>채널 편집을 열어 알아보기 쉬운 이름을 지정하고 받은 편지함 및 할당 설정을 검토한 뒤 저장합니다.</li><li>다른 Facebook 계정에서 테스트 메시지를 보냅니다. 올바른 받은 편지함에서 수신되는지 확인하고 답장도 테스트합니다.</li></ol><p>페이지가 없으면 계정 접근 권한과 허용 권한을 확인한 뒤 다시 인증하세요. 메시지나 답장이 오지 않으면 연결 상태를 점검하고 필요하면 재연결합니다. 다른 받은 편지함으로 오면 해당 받은 편지함의 팀 및 협업자 설정을 확인하세요.</p>" }
              }
            },
            {
              key: :instagram_direct_setup,
              position: 5,
              translations: {
                en: {
                  title: "Connect an Instagram Direct Channel",
                  content: <<~HTML
                    <p>Connect the Instagram account you use for customer support so Instagram Direct conversations can be handled in Deskbolic. The person completing authorization must be able to access the account and approve the permissions requested in the connection flow.</p>
                    <ol>
                      <li>Open <strong>Settings &rarr; Channels &rarr; Instagram</strong> and select <strong>Continue with Instagram</strong>.</li>
                      <li>Sign in to the Instagram account you intend to connect and review the permissions requested by Meta. Grant the permissions needed to continue.</li>
                      <li>Return to Deskbolic and confirm the Instagram profile appears in the channel list. Open its edit page, set a clear channel name, and review Inbox Settings.</li>
                      <li>From a separate Instagram account, send a test Direct message. Confirm it appears in the intended Deskbolic inbox, then test an agent reply.</li>
                    </ol>
                    <h3>Troubleshoot Instagram connection</h3>
                    <ul>
                      <li>If authorization is cancelled or fails, retry while signed in to the intended Instagram account and grant the permissions shown in the flow.</li>
                      <li>If the account is not listed after authorization, return to the Instagram setup page and reconnect the account.</li>
                      <li>If messages or replies stop working, check the channel's connection status and repeat Instagram authorization from the channel setup page.</li>
                      <li>If a conversation is visible to the wrong teammates, review inbox collaborators, teams, and assignment settings.</li>
                    </ul>
                  HTML
                },
                de: { title: "Instagram-Direct-Kanal verbinden", content: "<p>Verbinden Sie das Instagram-Konto Ihres Supports, damit Direct-Nachrichten in Deskbolic bearbeitet werden können. Das Konto für die Autorisierung muss Zugriff auf das gewünschte Instagram-Profil haben.</p><ol><li>Öffnen Sie <strong>Settings &rarr; Channels &rarr; Instagram</strong> und wählen Sie <strong>Continue with Instagram</strong>.</li><li>Melden Sie sich beim vorgesehenen Instagram-Konto an und prüfen Sie die von Meta angezeigten Berechtigungen. Erteilen Sie die erforderlichen Freigaben.</li><li>Kehren Sie zu Deskbolic zurück und bestätigen Sie, dass das Profil in der Kanalliste erscheint.</li><li>Öffnen Sie die Kanalbearbeitung, vergeben Sie einen verständlichen Namen und prüfen Sie die Postfach-, Team- und Zuweisungseinstellungen.</li><li>Senden Sie von einem anderen Instagram-Konto eine Test-Direktnachricht und prüfen Sie Eingang sowie Antwort.</li></ol><p>Wird das Profil nicht angezeigt, wiederholen Sie die Verbindung mit dem richtigen Konto und den erforderlichen Berechtigungen. Prüfen Sie bei fehlenden Nachrichten den Verbindungsstatus und autorisieren Sie erneut. Bei falscher Sichtbarkeit kontrollieren Sie die Mitarbeiter- und Teamzuweisungen.</p>" },
                es: { title: "Conectar un canal de Instagram Direct", content: "<p>Conecte la cuenta de Instagram de soporte para gestionar los mensajes Direct en Deskbolic. La persona que autoriza debe tener acceso al perfil previsto.</p><ol><li>Abra <strong>Settings &rarr; Channels &rarr; Instagram</strong> y seleccione <strong>Continue with Instagram</strong>.</li><li>Acceda a la cuenta deseada, revise los permisos mostrados por Meta y concédalos para continuar.</li><li>Vuelva a Deskbolic y confirme que el perfil aparece en la lista de canales.</li><li>Abra la edición, asigne un nombre claro y revise la bandeja, los equipos y los ajustes de asignación.</li><li>Desde otra cuenta de Instagram, envíe un mensaje Direct de prueba y compruebe la recepción y una respuesta.</li></ol><p>Si el perfil no aparece, repita el proceso con la cuenta correcta y los permisos necesarios. Si dejan de llegar mensajes, revise el estado y vuelva a autorizar. Si lo ven compañeros incorrectos, compruebe los colaboradores y equipos asignados.</p>" },
                fr: { title: "Connecter un canal Instagram Direct", content: "<p>Connectez le compte Instagram du support pour traiter les messages Direct dans Deskbolic. La personne qui autorise la connexion doit avoir accès au profil visé.</p><ol><li>Ouvrez <strong>Settings &rarr; Channels &rarr; Instagram</strong> et sélectionnez <strong>Continue with Instagram</strong>.</li><li>Connectez-vous au compte souhaité, examinez les autorisations de Meta et accordez celles qui sont requises.</li><li>Revenez dans Deskbolic et vérifiez que le profil apparaît dans la liste des canaux.</li><li>Ouvrez la modification du canal, donnez-lui un nom explicite et vérifiez la boîte, les équipes et l'attribution.</li><li>Depuis un autre compte Instagram, envoyez un message Direct test et vérifiez sa réception et une réponse.</li></ol><p>Si le profil est absent, recommencez avec le bon compte et les autorisations nécessaires. Si les messages cessent d'arriver, vérifiez l'état de connexion et réautorisez. Si des collègues inadéquats voient les conversations, vérifiez les équipes et collaborateurs affectés.</p>" },
                "pt-BR": { title: "Conectar um canal do Instagram Direct", content: "<p>Conecte a conta de suporte do Instagram para atender mensagens Direct no Deskbolic. Quem autorizar precisa ter acesso ao perfil desejado.</p><ol><li>Abra <strong>Settings &rarr; Channels &rarr; Instagram</strong> e selecione <strong>Continue with Instagram</strong>.</li><li>Entre na conta desejada, confira as permissões exibidas pela Meta e conceda as necessárias.</li><li>Volte ao Deskbolic e confirme que o perfil aparece na lista de canais.</li><li>Abra a edição do canal, defina um nome claro e revise a caixa, equipes e atribuição.</li><li>De outra conta do Instagram, envie uma mensagem Direct de teste e confira o recebimento e uma resposta.</li></ol><p>Se o perfil não aparecer, refaça a conexão com a conta correta e as permissões necessárias. Se as mensagens pararem, confira o status e autorize novamente. Se colegas errados tiverem acesso, revise as equipes e os colaboradores da caixa.</p>" },
                ar: { title: "ربط قناة Instagram Direct", content: "<p>اربط حساب Instagram المخصص للدعم لمعالجة رسائل Direct في Deskbolic. يجب أن يملك الشخص الذي يفوض الاتصال صلاحية الوصول إلى الملف المطلوب.</p><ol><li>افتح <strong>Settings &rarr; Channels &rarr; Instagram</strong> واختر <strong>Continue with Instagram</strong>.</li><li>سجّل الدخول إلى الحساب المقصود وراجع أذونات Meta وامنح الأذونات المطلوبة.</li><li>عد إلى Deskbolic وتحقق من ظهور الملف في قائمة القنوات.</li><li>افتح تعديل القناة، واكتب اسمًا واضحًا، وراجع إعدادات الصندوق والفرق والتعيين.</li><li>أرسل رسالة Direct اختبار من حساب Instagram آخر وتحقق من وصولها وإمكانية الرد.</li></ol><p>إذا لم يظهر الملف، أعد الربط بالحساب الصحيح والأذونات المطلوبة. إذا توقفت الرسائل، تحقق من حالة الاتصال وأعد التفويض. وإذا شاهدها زملاء غير مناسبين، راجع الفرق والمتعاونين المعينين.</p>" },
                ko: { title: "Instagram Direct 채널 연결", content: "<p>지원용 Instagram 계정을 연결하면 Deskbolic에서 Direct 메시지를 처리할 수 있습니다. 인증을 진행하는 계정은 연결할 프로필에 접근할 수 있어야 합니다.</p><ol><li><strong>Settings &rarr; Channels &rarr; Instagram</strong>에서 <strong>Continue with Instagram</strong>을 선택합니다.</li><li>대상 계정으로 로그인하고 Meta가 표시하는 권한을 확인한 뒤 필요한 권한을 허용합니다.</li><li>Deskbolic으로 돌아와 채널 목록에 프로필이 표시되는지 확인합니다.</li><li>채널 편집에서 알아보기 쉬운 이름을 정하고 받은 편지함, 팀, 할당 설정을 검토합니다.</li><li>다른 Instagram 계정에서 Direct 테스트 메시지를 보내 수신과 답장을 확인합니다.</li></ol><p>프로필이 표시되지 않으면 올바른 계정과 필요한 권한으로 다시 연결하세요. 메시지가 오지 않으면 연결 상태를 점검하고 다시 인증합니다. 잘못된 팀원이 대화를 보면 받은 편지함의 팀 및 협업자 설정을 확인하세요.</p>" }
              }
            },
            {
              key: :contact_form_setup,
              position: 6,
              translations: {
                en: {
                  title: "Create and Embed a Contact Form Channel",
                  content: <<~HTML
                    <p>A Contact Form channel gives website visitors a form for starting a support conversation. Replies are sent using the Email channel you select.</p>
                    <ol>
                      <li>First create and configure an Email channel if you do not already have one for replies.</li>
                      <li>Open <strong>Settings &rarr; Channels &rarr; Contact Form Channels</strong> and create a channel. Set its name, select the outbound Email channel, and optionally enter a redirect URL.</li>
                      <li>Configure the form's appearance, translations, and fields. Add fields from the available custom fields, arrange their order, and choose required status and width where offered.</li>
                      <li>Review the channel's Inbox Settings, such as collaborators, assignment, business hours, SLA policies, CSAT, and reply template.</li>
                      <li>Save the channel and copy its generated embed code from the details page. Add the code to the website page where the form should appear.</li>
                      <li>Submit a test form. Confirm the conversation reaches the intended inbox, the visitor's information is captured, and replies use the selected Email channel.</li>
                    </ol>
                    <h3>Troubleshoot form submissions</h3>
                    <ul>
                      <li>If the form is missing, check that the full generated embed code is deployed on the intended page.</li>
                      <li>If a submission cannot be created, check that the channel is saved and that required form fields are completed.</li>
                      <li>If outbound replies fail, verify the selected Email channel and its email connection settings.</li>
                      <li>If the submitter lands on an unexpected page, review the configured redirect URL.</li>
                    </ul>
                  HTML
                },
                de: { title: "Kontaktformular-Kanal erstellen und einbetten", content: "<p>Erstellen Sie zuerst einen E-Mail-Kanal für Antworten. Öffnen Sie <strong>Settings &rarr; Channels &rarr; Contact Form Channels</strong>, legen Sie Name, Antwortkanal und optional eine Weiterleitungs-URL fest. Konfigurieren Sie Darstellung, Übersetzungen und Formularfelder sowie die Postfacheinstellungen. Speichern Sie den Kanal, kopieren Sie den Einbettungscode von der Detailseite und fügen Sie ihn Ihrer Website hinzu. Senden Sie eine Testanfrage und prüfen Sie Eingang und Antwort. Bei Problemen kontrollieren Sie den veröffentlichten Code, Pflichtfelder, den E-Mail-Kanal und die Weiterleitungs-URL.</p>" },
                es: { title: "Crear e insertar un canal de formulario de contacto", content: "<p>Primero cree un canal de correo para responder. Abra <strong>Settings &rarr; Channels &rarr; Contact Form Channels</strong>, defina el nombre, el canal de salida y, si lo desea, una URL de redirección. Configure aspecto, traducciones, campos y ajustes de la bandeja. Guarde, copie el código de inserción de la página de detalles y añádalo a su sitio. Envíe una solicitud de prueba y compruebe la conversación y la respuesta. Si falla, revise el código publicado, los campos obligatorios, el canal de correo y la URL.</p>" },
                fr: { title: "Créer et intégrer un formulaire de contact", content: "<p>Créez d'abord un canal e-mail pour les réponses. Ouvrez <strong>Settings &rarr; Channels &rarr; Contact Form Channels</strong>, indiquez le nom, le canal sortant et, si besoin, une URL de redirection. Configurez l'apparence, les traductions, les champs et les paramètres de la boîte. Enregistrez, copiez le code d'intégration depuis la page de détails et ajoutez-le au site. Envoyez une demande de test et vérifiez la conversation et la réponse. En cas de problème, vérifiez le code publié, les champs obligatoires, le canal e-mail et l'URL.</p>" },
                "pt-BR": { title: "Criar e incorporar um formulário de contato", content: "<p>Crie primeiro um canal de e-mail para responder. Abra <strong>Settings &rarr; Channels &rarr; Contact Form Channels</strong>, informe o nome, o canal de saída e, se necessário, uma URL de redirecionamento. Configure aparência, traduções, campos e ajustes da caixa. Salve, copie o código de incorporação na página de detalhes e adicione-o ao site. Envie uma solicitação de teste e confira a conversa e a resposta. Se falhar, verifique o código publicado, os campos obrigatórios, o canal de e-mail e a URL.</p>" },
                ar: { title: "إنشاء نموذج اتصال وتضمينه", content: "<p>أنشئ أولًا قناة بريد إلكتروني للردود. افتح <strong>Settings &rarr; Channels &rarr; Contact Form Channels</strong> وأدخل الاسم وقناة الإرسال وعنوان إعادة التوجيه اختياريًا. اضبط المظهر والترجمات والحقول وإعدادات صندوق الوارد. احفظ القناة وانسخ رمز التضمين من صفحة التفاصيل وأضفه إلى موقعك. أرسل طلب اختبار وتحقق من إنشاء المحادثة والرد. عند حدوث مشكلة، تحقق من الرمز المنشور والحقول المطلوبة وقناة البريد وعنوان إعادة التوجيه.</p>" },
                ko: { title: "문의 양식 채널 만들기 및 삽입", content: "<p>먼저 답장에 사용할 이메일 채널을 만드세요. <strong>Settings &rarr; Channels &rarr; Contact Form Channels</strong>에서 채널 이름, 발신 이메일 채널, 선택적 리디렉션 URL을 설정합니다. 모양, 번역, 필드와 받은 편지함 설정을 구성하세요. 저장한 뒤 상세 페이지에서 삽입 코드를 복사해 웹사이트에 추가합니다. 테스트 요청을 제출해 상담 생성과 답장을 확인하세요. 문제가 있으면 배포한 코드, 필수 필드, 이메일 채널, 리디렉션 URL을 점검하세요.</p>" }
              }
            },
            {
              key: :custom_channel_setup,
              position: 7,
              translations: {
                en: {
                  title: "Configure and Test a Custom Channel",
                  content: <<~HTML
                    <p>Custom Channels connect Deskbolic to an integration that sends inbound messages to Deskbolic and receives agent replies through your webhook. You will need an HTTPS endpoint that can receive webhook requests and the ability to implement the integration's request and response format.</p>
                    <ol>
                      <li>Open <strong>Settings &rarr; Channels &rarr; Custom Channels</strong> and create a channel with a name and description.</li>
                      <li>In the channel's outbound settings, enter your publicly reachable HTTPS webhook URL. Add any required request headers using the header builder.</li>
                      <li>Save the channel. From the edit page, copy the generated Deskbolic inbound webhook endpoint and the webhook secret. Configure your integration to send inbound events to the endpoint and verify Deskbolic requests using the secret, following the protocol shown in the channel's developer guide.</li>
                      <li>Configure Response Mapping to map JSON paths from your inbound payload to the Deskbolic customer attributes offered in the selector.</li>
                      <li>Use <strong>Testing Tools</strong>: fire a mock outbound event to confirm your webhook receives it, and submit a sample inbound JSON payload to check the attribute mapping.</li>
                      <li>Send an end-to-end test through your integration and confirm the conversation appears in the intended inbox and an agent reply reaches your system.</li>
                    </ol>
                    <p>Keep the webhook secret private and store it in your server-side secret manager. Do not paste secrets into public website code, source control, or customer-facing messages.</p>
                    <h3>Troubleshoot a custom channel</h3>
                    <ul>
                      <li>If outbound tests fail, check that the URL is reachable over HTTPS, your server accepts the configured headers, and its logs show the request and response.</li>
                      <li>If inbound mapping is empty, verify the JSON paths against the exact sample payload and map only attributes offered in the selector.</li>
                      <li>If test mapping works but conversations do not appear, verify your integration sends the expected inbound request to the copied Deskbolic endpoint and inspect its response.</li>
                    </ul>
                  HTML
                },
                de: { title: "Benutzerdefinierten Kanal konfigurieren und testen", content: "<p>Öffnen Sie <strong>Settings &rarr; Channels &rarr; Custom Channels</strong> und erstellen Sie einen Kanal mit Namen und Beschreibung. Tragen Sie Ihre öffentlich erreichbare HTTPS-Webhook-URL und benötigte Header ein. Speichern Sie, kopieren Sie den Deskbolic-Eingangs-Endpunkt und das Geheimnis und konfigurieren Sie Ihre Integration gemäß dem Entwicklerleitfaden. Richten Sie Response Mapping mit JSON-Pfaden ein. Testen Sie ausgehende Webhooks und eingehende Zuordnungen in <strong>Testing Tools</strong>, danach den vollständigen Nachrichtenfluss. Halten Sie das Geheimnis serverseitig und geheim. Bei Fehlern prüfen Sie Erreichbarkeit, Header, JSON-Pfade und die Antwort Ihres Servers.</p>" },
                es: { title: "Configurar y probar un canal personalizado", content: "<p>Abra <strong>Settings &rarr; Channels &rarr; Custom Channels</strong> y cree un canal con nombre y descripción. Introduzca la URL HTTPS pública de su webhook y los encabezados necesarios. Guarde, copie el endpoint de entrada de Deskbolic y el secreto, y configure la integración según la guía para desarrolladores. Configure Response Mapping con rutas JSON. Use <strong>Testing Tools</strong> para probar webhooks salientes y la asignación de datos entrantes; después pruebe el flujo completo. Mantenga el secreto en el servidor y privado. Si falla, revise accesibilidad, encabezados, rutas JSON y la respuesta de su servidor.</p>" },
                fr: { title: "Configurer et tester un canal personnalisé", content: "<p>Ouvrez <strong>Settings &rarr; Channels &rarr; Custom Channels</strong> et créez un canal avec un nom et une description. Saisissez l'URL HTTPS publique de votre webhook et les en-têtes requis. Enregistrez, copiez le point d'entrée Deskbolic et le secret, puis configurez l'intégration selon le guide développeur. Définissez Response Mapping avec des chemins JSON. Dans <strong>Testing Tools</strong>, testez les webhooks sortants et le mappage entrant, puis le flux complet. Gardez le secret sur votre serveur et confidentiel. En cas d'échec, vérifiez l'accessibilité, les en-têtes, les chemins JSON et la réponse de votre serveur.</p>" },
                "pt-BR": { title: "Configurar e testar um canal personalizado", content: "<p>Abra <strong>Settings &rarr; Channels &rarr; Custom Channels</strong> e crie um canal com nome e descrição. Informe a URL HTTPS pública do webhook e os cabeçalhos necessários. Salve, copie o endpoint de entrada do Deskbolic e o segredo e configure a integração conforme o guia do desenvolvedor. Configure o Response Mapping com caminhos JSON. Em <strong>Testing Tools</strong>, teste webhooks de saída e o mapeamento de entrada; depois teste o fluxo completo. Mantenha o segredo privado no servidor. Se falhar, confira acessibilidade, cabeçalhos, caminhos JSON e a resposta do servidor.</p>" },
                ar: { title: "إعداد قناة مخصصة واختبارها", content: "<p>افتح <strong>Settings &rarr; Channels &rarr; Custom Channels</strong> وأنشئ قناة باسم ووصف. أدخل عنوان HTTPS العام للـ webhook والرؤوس المطلوبة. احفظ وانسخ نقطة استقبال Deskbolic والسر، ثم اضبط تكاملك وفق دليل المطور. أعد Response Mapping باستخدام مسارات JSON. استخدم <strong>Testing Tools</strong> لاختبار الأحداث الصادرة ومواءمة البيانات الواردة، ثم اختبر التدفق كاملًا. احتفظ بالسر على الخادم ولا تشاركه. عند الفشل تحقق من إمكانية الوصول والرؤوس ومسارات JSON واستجابة خادمك.</p>" },
                ko: { title: "사용자 지정 채널 구성 및 테스트", content: "<p><strong>Settings &rarr; Channels &rarr; Custom Channels</strong>에서 이름과 설명을 입력해 채널을 만드세요. 공개 HTTPS 웹훅 URL과 필요한 헤더를 입력합니다. 저장 후 Deskbolic 수신 엔드포인트와 비밀 키를 복사해 개발자 가이드에 따라 연동을 구성하세요. JSON 경로를 사용해 Response Mapping을 설정합니다. <strong>Testing Tools</strong>에서 발신 웹훅과 수신 데이터 매핑을 테스트한 뒤 전체 메시지 흐름을 확인하세요. 비밀 키는 서버에서 비공개로 보관합니다. 실패하면 URL 접근성, 헤더, JSON 경로와 서버 응답을 확인하세요.</p>" }
              }
            }
          ]
        end
      end
    end
  end
end
