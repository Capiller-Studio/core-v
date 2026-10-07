# frozen_string_literal: true

module Seeds
  module Data
    module ProductDocs
      module CsatAndAnalytics
        def self.category
          {
            key: :csat_and_analytics,
            icon_key: "bar-chart-2",
            position: 8,
            translations: {
              en: {
                name: "CSAT Surveys & Analytics",
                description: "Track customer satisfaction (CSAT) ratings, monitor agent performance metrics, and analyze conversation volume trends."
              },
              de: {
                name: "CSAT-Umfragen & Analysen",
                description: "Messen Sie die Kundenzufriedenheit und analysieren Sie Reaktionszeiten und Leistungskennzahlen."
              },
              es: {
                name: "Encuestas CSAT y Análisis",
                description: "Mida la satisfacción del cliente y analice métricas de rendimiento del equipo de soporte."
              },
              fr: {
                name: "Enquêtes CSAT et Statistiques",
                description: "Mesurez la satisfaction client et analysez les indicateurs de performance de vos conseillers."
              },
              "pt-BR": {
                name: "Pesquisas CSAT e Relatórios",
                description: "Monitore a satisfação do cliente (CSAT), tempos de resposta e indicadores de desempenho da equipe."
              },
              ar: {
                name: "استطلاعات رضا العملاء (CSAT) والتحليلات",
                description: "تتبع تقييمات رضا العملاء، وراقب مؤشرات أداء الوكلاء، وحلل اتجاهات حجم المحادثات."
              },
              ko: {
                name: "고객 만족도(CSAT) 및 통계 분석",
                description: "상담 완료 후 고객 만족도(CSAT) 자동 설문 조사, 응답 시간 통계 및 상담원 성과 분석 가이드입니다."
              }
            }
          }
        end

        def self.articles
          [
            {
              key: :csat_surveys_setup,
              position: 1,
              translations: {
                en: {
                  title: "Automated CSAT Customer Satisfaction Surveys",
                  content: <<~HTML
                    <p>Create a CSAT survey, then enable it on the inboxes where you want to collect customer feedback. Survey prompts and feedback-page text can be translated for supported languages.</p>
                    <h3>Create the survey</h3>
                    <ol>
                      <li>Open <strong>Settings &rarr; CSAT Surveys</strong> and create a survey.</li>
                      <li>Set its internal name, customer prompt, feedback-page title, and any optional subtitle or feedback label.</li>
                      <li>Add translations for the languages you need and save the survey.</li>
                    </ol>
                    <h3>Enable it on an inbox</h3>
                    <ol>
                      <li>Edit the channel whose inbox should collect feedback.</li>
                      <li>In <strong>Inbox Settings</strong>, enable the CSAT survey option and choose the survey.</li>
                      <li>Save the channel, resolve a test conversation, and confirm the survey is presented as expected for that channel.</li>
                    </ol>
                    <p>CSAT is configured per inbox. Creating a survey alone does not enable it for every channel.</p>
                  HTML
                },
                de: {
                  title: "Automatische CSAT-Zufriedenheitsumfragen",
                  content: "<p>Erstellen Sie eine CSAT-Umfrage und aktivieren Sie sie anschließend in jedem Postfach, in dem Sie Feedback erfassen möchten. Fragen und Seitentexte lassen sich übersetzen.</p><h3>Umfrage erstellen</h3><ol><li>Öffnen Sie <strong>Settings → CSAT Surveys</strong> und erstellen Sie eine Umfrage.</li><li>Legen Sie den internen Namen, die Kundenfrage, den Titel der Feedback-Seite sowie optionale Untertitel oder Feedback-Beschriftungen fest.</li><li>Ergänzen Sie benötigte Sprachen und speichern Sie.</li></ol><h3>Im Postfach aktivieren</h3><ol><li>Bearbeiten Sie den Kanal mit dem gewünschten Postfach.</li><li>Aktivieren Sie unter <strong>Inbox Settings</strong> die CSAT-Umfrage und wählen Sie Ihre Umfrage aus.</li><li>Speichern und testen Sie eine gelöste Konversation.</li></ol><p>Die Umfrage wird pro Postfach konfiguriert; das Erstellen aktiviert sie nicht überall.</p>"
                },
                es: {
                  title: "Encuestas Automatizadas de Satisfacción CSAT",
                  content: "<p>Cree una encuesta CSAT y actívela en cada bandeja donde quiera recibir comentarios. Puede traducir la pregunta y los textos de la página de comentarios.</p><h3>Crear la encuesta</h3><ol><li>Abra <strong>Settings → CSAT Surveys</strong> y cree una encuesta.</li><li>Configure el nombre interno, la pregunta, el título de la página de comentarios y los textos opcionales.</li><li>Añada los idiomas necesarios y guarde.</li></ol><h3>Activarla en una bandeja</h3><ol><li>Edite el canal de la bandeja donde recopilará opiniones.</li><li>En <strong>Inbox Settings</strong>, active CSAT y seleccione la encuesta.</li><li>Guarde y pruebe resolviendo una conversación.</li></ol><p>CSAT se configura por bandeja; crear una encuesta no la activa en todas.</p>"
                },
                fr: {
                  title: "Enquêtes de Satisfaction Client CSAT Automatisées",
                  content: "<p>Créez une enquête CSAT, puis activez-la dans chaque boîte où vous souhaitez recueillir des avis. La question et les textes de la page peuvent être traduits.</p><h3>Créer l'enquête</h3><ol><li>Ouvrez <strong>Settings → CSAT Surveys</strong> et créez une enquête.</li><li>Définissez le nom interne, la question, le titre de la page de commentaires et les textes facultatifs.</li><li>Ajoutez les langues nécessaires et enregistrez.</li></ol><h3>Activer dans une boîte</h3><ol><li>Modifiez le canal de la boîte concernée.</li><li>Dans <strong>Inbox Settings</strong>, activez CSAT et sélectionnez l'enquête.</li><li>Enregistrez et testez en résolvant une conversation.</li></ol><p>Le réglage est propre à chaque boîte ; créer une enquête ne l'active pas partout.</p>"
                },
                "pt-BR": {
                  title: "Pesquisas de Satisfação CSAT Automatizadas",
                  content: "<p>Crie uma pesquisa CSAT e ative-a em cada caixa de entrada onde deseja receber avaliações. A pergunta e os textos da página podem ser traduzidos.</p><h3>Criar a pesquisa</h3><ol><li>Abra <strong>Settings → CSAT Surveys</strong> e crie uma pesquisa.</li><li>Defina o nome interno, a pergunta, o título da página de feedback e textos opcionais.</li><li>Adicione os idiomas necessários e salve.</li></ol><h3>Ativar em uma caixa</h3><ol><li>Edite o canal da caixa que coletará as avaliações.</li><li>Em <strong>Inbox Settings</strong>, ative o CSAT e selecione a pesquisa.</li><li>Salve e teste resolvendo uma conversa.</li></ol><p>A configuração é por caixa; criar uma pesquisa não a ativa em todas elas.</p>"
                },
                ar: {
                  title: "استطلاعات رضا العملاء التلقائية (CSAT)",
                  content: "<p>أنشئ استطلاع CSAT وفعّله في كل صندوق وارد تريد جمع التقييمات فيه. يمكن ترجمة السؤال ونصوص صفحة الملاحظات.</p><h3>إنشاء الاستطلاع</h3><ol><li>افتح <strong>Settings → CSAT Surveys</strong> وأنشئ استطلاعًا.</li><li>حدد الاسم الداخلي وسؤال العميل وعنوان صفحة الملاحظات والنصوص الاختيارية.</li><li>أضف اللغات المطلوبة واحفظ.</li></ol><h3>تفعيله في صندوق وارد</h3><ol><li>عدّل القناة المرتبطة بصندوق الوارد المطلوب.</li><li>من <strong>Inbox Settings</strong> فعّل CSAT واختر الاستطلاع.</li><li>احفظ واختبر بحل محادثة تجريبية.</li></ol><p>إعداد CSAT خاص بكل صندوق وارد؛ إنشاء الاستطلاع لا يفعّله في البقية.</p>"
                },
                ko: {
                  title: "고객 만족도(CSAT) 자동 설문 조사 설정",
                  content: "<p>CSAT 설문을 만든 다음 고객 평가를 받을 각 받은 편지함에서 활성화하세요. 질문과 피드백 페이지 문구는 언어별로 번역할 수 있습니다.</p><h3>설문 만들기</h3><ol><li><strong>Settings → CSAT Surveys</strong>를 열고 설문을 만듭니다.</li><li>내부 이름, 고객 질문, 피드백 페이지 제목과 선택 문구를 설정합니다.</li><li>필요한 언어를 추가하고 저장합니다.</li></ol><h3>받은 편지함에서 활성화</h3><ol><li>평가를 받을 채널을 편집합니다.</li><li><strong>Inbox Settings</strong>에서 CSAT 설문을 켜고 설문을 선택합니다.</li><li>저장한 뒤 테스트 대화를 해결해 동작을 확인합니다.</li></ol><p>CSAT는 받은 편지함별 설정입니다. 설문을 만들기만 해서는 다른 받은 편지함에서 활성화되지 않습니다.</p>"
                }
              }
            }
          ]
        end
      end
    end
  end
end
