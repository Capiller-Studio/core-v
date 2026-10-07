# frozen_string_literal: true

module Seeds
  module Data
    module ProductDocs
      module AiAgentsAndCopilot
        def self.category
          {
            key: :ai_agents_and_copilot,
            icon_key: "bot",
            position: 4,
            translations: {
              en: {
                name: "AI Agents & AI Copilot",
                description: "Configure AI Agents for supported Web Widget channels and use AI Copilot tools to assist teammates."
              },
              de: {
                name: "KI-Agenten & KI-Copilot",
                description: "Richten Sie KI-Agenten für unterstützte Web-Widget-Kanäle ein und unterstützen Sie Ihr Team mit KI-Copilot."
              },
              es: {
                name: "Agentes de IA y Copiloto de IA",
                description: "Configure agentes de IA para canales Web Widget compatibles y ayude al equipo con AI Copilot."
              },
              fr: {
                name: "Agents IA et Copilote IA",
                description: "Configurez des agents IA pour les canaux Web Widget pris en charge et aidez votre équipe avec AI Copilot."
              },
              "pt-BR": {
                name: "Agentes de IA e Copiloto de IA",
                description: "Configure agentes de IA para canais Web Widget compatíveis e ajude a equipe com AI Copilot."
              },
              ar: {
                name: "وكلاء الذكاء الاصطناعي والمساعد الذكي (Copilot)",
                description: "اضبط وكلاء الذكاء الاصطناعي لقنوات Web Widget المدعومة واستخدم AI Copilot لمساعدة الفريق."
              },
              ko: {
                name: "AI 상담 에이전트 및 AI 코파일럿",
                description: "지원되는 Web Widget 채널에 AI Agent를 설정하고 AI Copilot으로 팀을 지원합니다."
              }
            }
          }
        end

        def self.articles
          [
            {
              key: :autonomous_ai_agents,
              position: 1,
              translations: {
                en: {
                  title: "Deploying Autonomous AI Support Agents",
                  content: <<~HTML
                    <p>Deskbolic AI Agents can handle conversations through a configured Web Widget inbox. Results depend on your agent instructions, connected help center content, and the customer's question; review conversations and handoffs before relying on automation.</p>
                    <h3>Setting Up an AI Agent</h3>
                    <ol>
                      <li>Open <strong>Settings &rarr; AI Agents</strong> and choose <strong>Add new agent</strong>.</li>
                      <li>Complete the agent's configuration and translations, including its greeting, handoff, and fallback messages.</li>
                      <li>To use an agent, edit a <strong>Web Widget</strong> channel and select it in the channel's <strong>AI Agent</strong> setting. AI Agent assignment is currently supported for Web Widget inboxes.</li>
                      <li>Test the widget, including questions the agent cannot answer, and confirm the handoff and fallback behavior before publishing it to customers.</li>
                    </ol>
                  HTML
                },
                de: {
                  title: "Autonome KI-Support-Agenten einsetzen",
                  content: "<p>Deskbolic AI Agents können Gespräche über einen konfigurierten Web-Widget-Posteingang bearbeiten. Die Ergebnisse hängen von Anweisungen, Help-Center-Inhalten und der Kundenfrage ab.</p><h3>Agent einrichten</h3><ol><li>Öffnen Sie <strong>Settings → AI Agents</strong> und wählen Sie <strong>Add new agent</strong>.</li><li>Konfigurieren Sie den Agenten und ergänzen Sie Übersetzungen für Begrüßung, Übergabe und Fallback.</li><li>Bearbeiten Sie einen <strong>Web Widget</strong>-Kanal und wählen Sie den Agenten in der Einstellung <strong>AI Agent</strong> aus. Die Zuweisung wird derzeit für Web Widgets unterstützt.</li><li>Testen Sie im Widget beantwortbare und unbeantwortbare Fragen sowie Übergabe und Fallback, bevor Sie es veröffentlichen.</li></ol>"
                },
                es: {
                  title: "Implementación de Agentes de Soporte de IA",
                  content: "<p>Los agentes de IA pueden atender conversaciones mediante una bandeja Web Widget configurada. El resultado depende de las instrucciones, el contenido del centro de ayuda y la pregunta.</p><h3>Configurar un agente</h3><ol><li>Abra <strong>Settings → AI Agents</strong> y seleccione <strong>Add new agent</strong>.</li><li>Configure el agente y traduzca sus mensajes de bienvenida, transferencia y respuesta alternativa.</li><li>Edite un canal <strong>Web Widget</strong> y selecciónelo en <strong>AI Agent</strong>. Actualmente, la asignación solo está disponible para Web Widget.</li><li>Pruebe preguntas que pueda responder y preguntas sin respuesta; confirme la transferencia y la alternativa antes de publicarlo.</li></ol>"
                },
                fr: {
                  title: "Déploiement d'Agents IA Autonomes",
                  content: "<p>Les agents IA peuvent traiter des conversations via une boîte Web Widget configurée. Les résultats dépendent des instructions, du centre d'aide et de la question du client.</p><h3>Configurer un agent</h3><ol><li>Ouvrez <strong>Settings → AI Agents</strong> et choisissez <strong>Add new agent</strong>.</li><li>Configurez l'agent et traduisez ses messages d'accueil, de transfert et de réponse de secours.</li><li>Modifiez un canal <strong>Web Widget</strong> et sélectionnez l'agent dans <strong>AI Agent</strong>. Cette attribution est actuellement prise en charge uniquement pour Web Widget.</li><li>Testez les questions avec et sans réponse et vérifiez le transfert avant la publication.</li></ol>"
                },
                "pt-BR": {
                  title: "Implementando Agentes de IA Autônomos",
                  content: "<p>Os agentes de IA atendem conversas por uma caixa Web Widget configurada. Os resultados dependem das instruções, do conteúdo da central de ajuda e da pergunta do cliente.</p><h3>Configurar um agente</h3><ol><li>Abra <strong>Settings → AI Agents</strong> e selecione <strong>Add new agent</strong>.</li><li>Configure o agente e traduza as mensagens de saudação, transferência e resposta alternativa.</li><li>Edite um canal <strong>Web Widget</strong> e selecione o agente em <strong>AI Agent</strong>. Atualmente, essa atribuição só é compatível com Web Widget.</li><li>Teste perguntas respondíveis e não respondíveis e confira a transferência antes de publicar.</li></ol>"
                },
                ar: {
                  title: "نشر وكلاء دعم الذكاء الاصطناعي الذاتيين",
                  content: "<p>يمكن لوكلاء الذكاء الاصطناعي التعامل مع المحادثات عبر صندوق وارد Web Widget مُعد. وتعتمد النتائج على التعليمات ومحتوى مركز المساعدة وسؤال العميل.</p><h3>إعداد وكيل</h3><ol><li>افتح <strong>Settings → AI Agents</strong> واختر <strong>Add new agent</strong>.</li><li>أكمل الإعدادات وترجمات التحية والتحويل والرد الاحتياطي.</li><li>عدّل قناة <strong>Web Widget</strong> واختر الوكيل في <strong>AI Agent</strong>. هذا الربط مدعوم حاليًا لقنوات Web Widget فقط.</li><li>اختبر أسئلة يمكن الإجابة عنها وأخرى لا يمكن الإجابة عنها، وتحقق من التحويل والرد الاحتياطي قبل النشر.</li></ol>"
                },
                ko: {
                  title: "자율 AI 상담 에이전트 배포 가이드",
                  content: "<p>AI Agent는 설정된 Web Widget 받은 편지함에서 대화를 처리합니다. 결과는 지침, 연결된 도움말 콘텐츠와 고객 질문에 따라 달라집니다.</p><h3>에이전트 설정</h3><ol><li><strong>Settings → AI Agents</strong>를 열고 <strong>Add new agent</strong>를 선택합니다.</li><li>에이전트를 구성하고 인사, 상담원 연결, 대체 응답 문구를 번역합니다.</li><li><strong>Web Widget</strong> 채널을 편집하고 <strong>AI Agent</strong> 설정에서 에이전트를 선택합니다. 현재 Web Widget만 지원됩니다.</li><li>답변 가능한 질문과 불가능한 질문을 테스트하고 공개 전에 상담원 연결 및 대체 응답을 확인합니다.</li></ol>"
                }
              }
            },
            {
              key: :ai_copilot_assistant,
              position: 2,
              translations: {
                en: {
                  title: "AI Copilot: Real-Time Agent Assistance",
                  content: <<~HTML
                    <p>AI Copilot assists human agents inside the conversation composer with intelligent reply drafting, tone adjustment, and summarization.</p>
                    <h3>Key Capabilities</h3>
                    <ul>
                      <li><strong>Suggest Reply:</strong> Generates context-aware response drafts based on conversation history and knowledge base.</li>
                      <li><strong>Fix Spelling &amp; Grammar:</strong> Instantly polishes drafted messages.</li>
                      <li><strong>Adjust Tone:</strong> Transform drafts to sound friendly, formal, concise, or empathetic.</li>
                      <li><strong>Summarize Conversation:</strong> Creates bullet-point executive summaries for handover between agents.</li>
                    </ul>
                  HTML
                },
                de: {
                  title: "KI-Copilot: Echtzeit-Unterstützung für Agenten",
                  content: "<p>Der KI-Copilot unterstützt menschliche Agenten im Antwortfeld beim Erstellen und Überarbeiten von Antworten.</p><h3>Verfügbare Hilfen</h3><ul><li><strong>Suggest Reply:</strong> Erstellt einen Antwortentwurf anhand des Gesprächsverlaufs und der verfügbaren Wissensquellen.</li><li><strong>Fix Spelling &amp; Grammar:</strong> Korrigiert Rechtschreibung und Grammatik eines Entwurfs.</li><li><strong>Adjust Tone:</strong> Passt den Ton an, zum Beispiel freundlicher, formeller, kürzer oder einfühlsamer.</li><li><strong>Summarize Conversation:</strong> Erstellt eine Zusammenfassung für die Übergabe an ein anderes Teammitglied.</li></ul><p>Prüfen und bearbeiten Sie KI-Vorschläge vor dem Senden.</p>"
                },
                es: {
                  title: "Copiloto de IA: Asistencia en Tiempo Real",
                  content: "<p>AI Copilot ayuda al agente desde el editor de respuestas con borradores y herramientas de revisión.</p><h3>Funciones disponibles</h3><ul><li><strong>Suggest Reply:</strong> propone un borrador según el historial y las fuentes de conocimiento disponibles.</li><li><strong>Fix Spelling &amp; Grammar:</strong> corrige la ortografía y la gramática del borrador.</li><li><strong>Adjust Tone:</strong> adapta el tono para que sea más amable, formal, breve o empático.</li><li><strong>Summarize Conversation:</strong> prepara un resumen para entregar la conversación a otro compañero.</li></ul><p>Revise y edite las sugerencias antes de enviarlas.</p>"
                },
                fr: {
                  title: "Copilote IA: Assistance en Temps Réel",
                  content: "<p>AI Copilot aide l'agent dans le compositeur à rédiger et améliorer ses réponses.</p><h3>Outils disponibles</h3><ul><li><strong>Suggest Reply:</strong> propose un brouillon selon l'historique et les sources de connaissance disponibles.</li><li><strong>Fix Spelling &amp; Grammar:</strong> corrige l'orthographe et la grammaire du brouillon.</li><li><strong>Adjust Tone:</strong> rend le texte plus amical, formel, concis ou empathique.</li><li><strong>Summarize Conversation:</strong> résume l'échange pour faciliter le relais à un collègue.</li></ul><p>Relisez et modifiez les propositions avant l'envoi.</p>"
                },
                "pt-BR": {
                  title: "Copiloto de IA: Assistência em Tempo Real",
                  content: "<p>O AI Copilot ajuda o atendente no editor de respostas a redigir e revisar mensagens.</p><h3>Ferramentas disponíveis</h3><ul><li><strong>Suggest Reply:</strong> sugere um rascunho com base no histórico e nas fontes de conhecimento disponíveis.</li><li><strong>Fix Spelling &amp; Grammar:</strong> corrige ortografia e gramática do rascunho.</li><li><strong>Adjust Tone:</strong> adapta o tom para ficar mais amigável, formal, conciso ou empático.</li><li><strong>Summarize Conversation:</strong> resume o atendimento para facilitar a transferência a outro colega.</li></ul><p>Revise e edite as sugestões antes de enviar.</p>"
                },
                ar: {
                  title: "المساعد الذكي (AI Copilot): دعم فوري للوكلاء",
                  content: "<p>يساعد AI Copilot الوكيل البشري داخل محرر الردود على كتابة الرسائل وتحسينها.</p><h3>الأدوات المتاحة</h3><ul><li><strong>Suggest Reply:</strong> يقترح مسودة استنادًا إلى سجل المحادثة ومصادر المعرفة المتاحة.</li><li><strong>Fix Spelling &amp; Grammar:</strong> يصحح الإملاء والقواعد في المسودة.</li><li><strong>Adjust Tone:</strong> يغيّر النبرة لتكون ودية أو رسمية أو موجزة أو متعاطفة.</li><li><strong>Summarize Conversation:</strong> ينشئ ملخصًا لتسهيل تسليم المحادثة إلى زميل.</li></ul><p>راجع اقتراحات الذكاء الاصطناعي وعدّلها قبل الإرسال.</p>"
                },
                ko: {
                  title: "AI 코파일럿: 상담원 실시간 작성 어시스턴트",
                  content: "<p>AI Copilot은 답장 작성기에서 상담원이 메시지를 작성하고 다듬도록 돕습니다.</p><h3>사용 가능한 기능</h3><ul><li><strong>Suggest Reply:</strong> 대화 내역과 사용 가능한 지식 자료를 바탕으로 답장 초안을 제안합니다.</li><li><strong>Fix Spelling &amp; Grammar:</strong> 초안의 맞춤법과 문법을 교정합니다.</li><li><strong>Adjust Tone:</strong> 친근함, 격식, 간결함, 공감 등으로 어조를 조정합니다.</li><li><strong>Summarize Conversation:</strong> 다른 상담원에게 인계할 수 있도록 대화를 요약합니다.</li></ul><p>AI 제안은 전송 전에 검토하고 수정하세요.</p>"
                }
              }
            }
          ]
        end
      end
    end
  end
end
