# frozen_string_literal: true

module Seeds
  module Data
    module ProductDocs
      module InboxesAndConversations
        def self.category
          {
            key: :inboxes_and_conversations,
            icon_key: "inbox",
            position: 2,
            translations: {
              en: {
                name: "Inboxes & Conversations",
                description: "Master the unified omnichannel inbox, conversation lifecycle, assigning tickets, private internal notes, and real-time collaboration."
              },
              de: {
                name: "Postfächer & Konversationen",
                description: "Verwalten Sie das einheitliche Postfach, Zuweisungen, interne Notizen und den Konversationslebenszyklus."
              },
              es: {
                name: "Bandejas y Conversaciones",
                description: "Domine la bandeja omnicanal unificada, asignaciones, notas privadas y el ciclo de vida de las conversaciones."
              },
              fr: {
                name: "Boîtes et Conversations",
                description: "Maîtrisez la boîte unifiée, l'attribution des tickets, les notes internes et la collaboration en temps réel."
              },
              "pt-BR": {
                name: "Caixas de Entrada e Conversas",
                description: "Domine a caixa multicanal unificada, atribuições, notas internas e o ciclo de vida dos atendimentos."
              },
              ar: {
                name: "صناديق الوارد والمحادثات",
                description: "تعلم كيفية إدارة صندوق الوارد الموحد متعدد القنوات، وتعيين التذاكر، والملاحظات الخاصة، وحالة المحادثات."
              },
              ko: {
                name: "받은 편지함 및 대화 관리",
                description: "통합 옴니채널 받은 편지함 활용법, 대화 담당자 배정, 내부 비공개 메모 및 실시간 협업 기능 가이드입니다."
              }
            }
          }
        end

        def self.articles
          [
            {
              key: :unified_inbox_views,
              position: 1,
              translations: {
                en: {
                  title: "Unified Inboxes & Smart Filter Views",
                  content: <<~HTML
                    <p>Capiller Rely aggregates all customer messages across all communication channels into a single unified queue.</p>
                    <h3>Smart Views</h3>
                    <ul>
                      <li><strong>Assigned to me:</strong> Conversations assigned to your account.</li>
                      <li><strong>Unassigned:</strong> Incoming customer tickets awaiting triage and agent assignment.</li>
                      <li><strong>All:</strong> Complete workspace conversation stream across all channels.</li>
                      <li><strong>Mentions:</strong> Conversations where a teammate mentioned you.</li>
                    </ul>
                  HTML
                },
                de: {
                  title: "Einheitliche Postfächer & Ansichten",
                  content: "<p>Capiller Rely bündelt Kundennachrichten aus den Kommunikationskanälen in einer Warteschlange. Die Ansichten helfen Ihnen, relevante Gespräche zu finden.</p><ul><li><strong>Assigned to me:</strong> Ihnen zugewiesene Konversationen.</li><li><strong>Unassigned:</strong> Eingehende Anfragen ohne zuständiges Teammitglied.</li><li><strong>All:</strong> Konversationen des Arbeitsbereichs über alle Kanäle.</li><li><strong>Mentions:</strong> Konversationen, in denen Sie erwähnt wurden.</li></ul><p>Öffnen Sie die passende Ansicht in der Seitenleiste und wählen Sie eine Konversation aus der Liste, um sie zu bearbeiten.</p>"
                },
                es: {
                  title: "Bandeja Unificada y Vistas Inteligentes",
                  content: "<p>Capiller Rely reúne los mensajes de los canales en una cola unificada. Las vistas ayudan a encontrar conversaciones que requieren atención.</p><ul><li><strong>Assigned to me:</strong> conversaciones asignadas a su usuario.</li><li><strong>Unassigned:</strong> consultas entrantes sin una persona responsable.</li><li><strong>All:</strong> conversaciones del espacio de trabajo en todos los canales.</li><li><strong>Mentions:</strong> conversaciones en las que un compañero le mencionó.</li></ul><p>Abra la vista adecuada en la barra lateral y seleccione una conversación para gestionarla.</p>"
                },
                fr: {
                  title: "Boîte Unifiée et Vues Intelligentes",
                  content: "<p>Capiller Rely rassemble les messages clients des différents canaux dans une file unifiée. Les vues permettent de repérer les conversations à traiter.</p><ul><li><strong>Assigned to me:</strong> conversations qui vous sont attribuées.</li><li><strong>Unassigned:</strong> demandes entrantes sans responsable.</li><li><strong>All:</strong> conversations de l'espace sur tous les canaux.</li><li><strong>Mentions:</strong> conversations dans lesquelles un collègue vous a mentionné.</li></ul><p>Ouvrez la vue souhaitée dans la barre latérale puis sélectionnez une conversation pour la traiter.</p>"
                },
                "pt-BR": {
                  title: "Caixa Unificada e Visualizações Inteligentes",
                  content: "<p>O Capiller Rely reúne mensagens dos canais em uma fila unificada. As visualizações ajudam a encontrar conversas que precisam de atenção.</p><ul><li><strong>Assigned to me:</strong> conversas atribuídas a você.</li><li><strong>Unassigned:</strong> solicitações recebidas sem responsável.</li><li><strong>All:</strong> conversas do espaço de trabalho em todos os canais.</li><li><strong>Mentions:</strong> conversas em que um colega mencionou você.</li></ul><p>Abra a visualização desejada na barra lateral e selecione uma conversa para atendê-la.</p>"
                },
                ar: {
                  title: "صناديق الوارد الموحدة وطرق العرض الذكية",
                  content: "<p>يجمع Capiller Rely رسائل العملاء من القنوات في قائمة موحدة، وتساعد طرق العرض في العثور على المحادثات التي تحتاج إلى متابعة.</p><ul><li><strong>Assigned to me:</strong> المحادثات المسندة إليك.</li><li><strong>Unassigned:</strong> الطلبات الواردة التي لم تُسند إلى مسؤول.</li><li><strong>All:</strong> محادثات مساحة العمل من جميع القنوات.</li><li><strong>Mentions:</strong> المحادثات التي أشار إليك فيها زميل.</li></ul><p>افتح طريقة العرض المناسبة من الشريط الجانبي واختر محادثة لمتابعتها.</p>"
                },
                ko: {
                  title: "통합 받은 편지함 및 스마트 필터 뷰",
                  content: "<p>Capiller Rely은 채널별 고객 메시지를 통합 큐에 모읍니다. 스마트 뷰를 사용해 확인할 대화를 찾으세요.</p><ul><li><strong>Assigned to me:</strong> 내게 배정된 대화.</li><li><strong>Unassigned:</strong> 담당자가 지정되지 않은 문의.</li><li><strong>All:</strong> 모든 채널의 워크스페이스 대화.</li><li><strong>Mentions:</strong> 팀원이 나를 언급한 대화.</li></ul><p>사이드바에서 뷰를 열고 목록의 대화를 선택해 처리합니다.</p>"
                }
              }
            },
            {
              key: :conversation_lifecycle,
              position: 2,
              translations: {
                en: {
                  title: "Conversation Lifecycle & Statuses",
                  content: <<~HTML
                    <p>Every conversation moves through distinct lifecycle stages to ensure no customer inquiry slips through the cracks:</p>
                    <ul>
                      <li><strong>Active / Open:</strong> Awaiting an agent or customer reply.</li>
                      <li><strong>Snoozed:</strong> Temporarily paused until a specific date/time (e.g. waiting for customer verification or follow-up).</li>
                      <li><strong>Resolved:</strong> Marked complete by the team. A later incoming message may reopen a conversation depending on the channel and its behavior.</li>
                    </ul>
                  HTML
                },
                de: {
                  title: "Konversationslebenszyklus & Status",
                  content: "<p>Konversationen durchlaufen Status, damit offene Anfragen nachverfolgt werden können.</p><ul><li><strong>Active / Open:</strong> Eine Antwort des Teams oder Kunden steht noch aus.</li><li><strong>Snoozed:</strong> Die Konversation ist bis zu einem gewählten Zeitpunkt pausiert, etwa bis zu einer Rückmeldung.</li><li><strong>Resolved:</strong> Das Team hat die Anfrage als abgeschlossen markiert. Eine neue Nachricht kann sie je nach Kanal wieder öffnen.</li></ul><p>Prüfen Sie den aktuellen Status in der Konversation und wählen Sie die passende Aktion, wenn Sie die Bearbeitung fortsetzen oder abschließen.</p>"
                },
                es: {
                  title: "Ciclo de Vida y Estados de la Conversación",
                  content: "<p>Los estados permiten seguir las consultas hasta que el equipo las resuelva.</p><ul><li><strong>Active / Open:</strong> queda pendiente una respuesta del equipo o del cliente.</li><li><strong>Snoozed:</strong> la conversación se pausa hasta la fecha u hora elegida, por ejemplo, mientras se espera una confirmación.</li><li><strong>Resolved:</strong> el equipo marcó la consulta como completada. Un mensaje nuevo puede reabrirla según el canal.</li></ul><p>Revise el estado actual en la conversación y elija la acción adecuada para continuar o finalizar la atención.</p>"
                },
                fr: {
                  title: "Cycle de Vie et Statuts des Conversations",
                  content: "<p>Les statuts permettent de suivre une demande jusqu'à sa résolution.</p><ul><li><strong>Active / Open:</strong> une réponse de l'équipe ou du client est attendue.</li><li><strong>Snoozed:</strong> la conversation est mise en pause jusqu'à la date ou l'heure choisie, par exemple en attente d'une confirmation.</li><li><strong>Resolved:</strong> l'équipe a terminé la demande. Un nouveau message peut la rouvrir selon le canal.</li></ul><p>Consultez le statut dans la conversation et choisissez l'action adaptée pour reprendre ou terminer le traitement.</p>"
                },
                "pt-BR": {
                  title: "Ciclo de Vida e Status das Conversas",
                  content: "<p>Os status ajudam a acompanhar uma solicitação até que ela seja resolvida.</p><ul><li><strong>Active / Open:</strong> ainda é necessária uma resposta da equipe ou do cliente.</li><li><strong>Snoozed:</strong> a conversa fica pausada até a data ou hora escolhida, por exemplo, enquanto se aguarda uma confirmação.</li><li><strong>Resolved:</strong> a equipe marcou a solicitação como concluída. Uma nova mensagem pode reabri-la, dependendo do canal.</li></ul><p>Confira o status na conversa e escolha a ação adequada para retomar ou encerrar o atendimento.</p>"
                },
                ar: {
                  title: "دورة حياة المحادثة وحالاتها",
                  content: "<p>تساعد الحالات الفريق على متابعة الطلب حتى إتمامه.</p><ul><li><strong>Active / Open:</strong> لا يزال الرد من الفريق أو العميل مطلوبًا.</li><li><strong>Snoozed:</strong> توقفت المحادثة مؤقتًا حتى التاريخ أو الوقت المحدد، مثل انتظار تأكيد من العميل.</li><li><strong>Resolved:</strong> وضع الفريق علامة على اكتمال الطلب. وقد تعيد رسالة جديدة فتح المحادثة حسب القناة.</li></ul><p>راجع الحالة الحالية في المحادثة واختر الإجراء المناسب لاستئناف العمل أو إنهائه.</p>"
                },
                ko: {
                  title: "대화 수명 주기 및 상태 관리",
                  content: "<p>대화 상태를 사용해 문의가 해결될 때까지 진행 상황을 추적합니다.</p><ul><li><strong>Active / Open:</strong> 팀 또는 고객의 답변을 기다리는 상태입니다.</li><li><strong>Snoozed:</strong> 고객 확인을 기다리는 동안처럼 지정한 날짜와 시간까지 대화를 일시 중지합니다.</li><li><strong>Resolved:</strong> 팀이 문의를 완료로 표시한 상태입니다. 채널에 따라 새 메시지가 오면 다시 열릴 수 있습니다.</li></ul><p>대화에서 현재 상태를 확인하고 계속 처리하거나 마무리할 적절한 작업을 선택하세요.</p>"
                }
              }
            },
            {
              key: :private_messages_and_user_notes,
              position: 3,
              translations: {
                en: {
                  title: "Use Private Messages and Customer User Notes",
                  content: <<~HTML
                    <p>Use a private message to discuss a conversation with teammates. Use <strong>User Notes</strong> in the customer details sidebar to keep context about the customer for future conversations. Both are internal collaboration tools; they are not customer replies.</p>
                    <h3>Add a private message to a conversation</h3>
                    <ol>
                      <li>Open the conversation and select <strong>Private Message</strong> in the composer.</li>
                      <li>Write the internal message and send it. Check that the composer is still set to Private Message before sending.</li>
                    </ol>
                    <h3>Add a customer note</h3>
                    <ol>
                      <li>Open a conversation with the customer and expand <strong>User Notes</strong> in the right-hand details sidebar.</li>
                      <li>Choose the add control, enter the note, and save it.</li>
                      <li>Return to the customer's profile in a later conversation to review the note when relevant.</li>
                    </ol>
                    <p>Keep notes factual, concise, and useful to the support team. Do not put a customer-facing response in User Notes; send it from the Reply composer instead.</p>
                  HTML
                },
                de: { title: "Private Nachrichten und Kundennotizen verwenden", content: "<p>Verwenden Sie eine private Nachricht für interne Absprachen zu einer einzelnen Konversation. Mit User Notes speichern Sie dagegen hilfreichen Kontext zum Kunden für spätere Gespräche. Beides ist intern und wird nicht als Antwort an den Kunden gesendet.</p><h3>Private Nachricht senden</h3><ol><li>Öffnen Sie die Konversation und wählen Sie im Editor <strong>Private Message</strong>.</li><li>Schreiben Sie die interne Nachricht und prüfen Sie vor dem Senden, dass weiterhin Private Message ausgewählt ist.</li></ol><h3>Kundennotiz speichern</h3><ol><li>Öffnen Sie eine Konversation mit dem Kunden und erweitern Sie <strong>User Notes</strong> in der rechten Seitenleiste.</li><li>Wählen Sie Hinzufügen, geben Sie die Notiz ein und speichern Sie.</li><li>Öffnen Sie bei einem späteren Gespräch erneut die Kundendetails, um die Notiz zu lesen.</li></ol><p>Notizen sollten sachlich, knapp und für das Supportteam nützlich sein. Kundenantworten senden Sie über Reply.</p>" },
                es: { title: "Usar mensajes privados y notas del cliente", content: "<p>Use un mensaje privado para hablar internamente sobre una conversación concreta. Use User Notes para conservar contexto útil del cliente para futuras conversaciones. Ambas funciones son internas y no se envían como respuesta.</p><h3>Enviar un mensaje privado</h3><ol><li>Abra la conversación y seleccione <strong>Private Message</strong> en el editor.</li><li>Escriba el mensaje interno y confirme que esa opción sigue seleccionada antes de enviarlo.</li></ol><h3>Guardar una nota del cliente</h3><ol><li>Abra una conversación del cliente y despliegue <strong>User Notes</strong> en la barra lateral derecha.</li><li>Use el control para añadir, escriba la nota y guárdela.</li><li>En una conversación posterior, vuelva a los detalles del cliente para consultar la nota.</li></ol><p>Las notas deben ser objetivas, breves y útiles para el equipo. Para responder al cliente, use Reply.</p>" },
                fr: { title: "Utiliser les messages privés et les notes client", content: "<p>Utilisez un message privé pour échanger en interne au sujet d'une conversation précise. Utilisez User Notes pour conserver un contexte client utile lors de prochaines conversations. Ces deux outils restent internes et ne sont pas envoyés comme réponse.</p><h3>Envoyer un message privé</h3><ol><li>Ouvrez la conversation et sélectionnez <strong>Private Message</strong> dans l'éditeur.</li><li>Rédigez le message interne et vérifiez que Private Message est toujours sélectionné avant l'envoi.</li></ol><h3>Enregistrer une note client</h3><ol><li>Ouvrez une conversation du client et développez <strong>User Notes</strong> dans la barre latérale droite.</li><li>Utilisez le bouton d'ajout, saisissez la note et enregistrez-la.</li><li>Lors d'une conversation ultérieure, rouvrez les détails du client pour consulter la note.</li></ol><p>Les notes doivent être factuelles, concises et utiles à l'équipe. Pour répondre au client, utilisez Reply.</p>" },
                "pt-BR": { title: "Usar mensagens privadas e notas do cliente", content: "<p>Use uma mensagem privada para conversar internamente sobre um atendimento específico. Use User Notes para guardar contexto útil do cliente para conversas futuras. Os dois recursos são internos e não são enviados como resposta.</p><h3>Enviar uma mensagem privada</h3><ol><li>Abra a conversa e selecione <strong>Private Message</strong> no editor.</li><li>Escreva a mensagem interna e confirme que Private Message continua selecionado antes de enviar.</li></ol><h3>Salvar uma nota do cliente</h3><ol><li>Abra uma conversa do cliente e expanda <strong>User Notes</strong> na barra lateral direita.</li><li>Use o controle de adicionar, escreva a nota e salve.</li><li>Em uma conversa futura, volte aos detalhes do cliente para consultar a nota.</li></ol><p>Mantenha as notas objetivas, breves e úteis para a equipe. Para responder ao cliente, use Reply.</p>" },
                ar: { title: "استخدام الرسائل الخاصة وملاحظات العميل", content: "<p>استخدم الرسالة الخاصة للنقاش الداخلي حول محادثة بعينها، واستخدم User Notes لحفظ سياق مفيد عن العميل للمحادثات اللاحقة. كلاهما داخلي ولا يُرسل كرسالة إلى العميل.</p><h3>إرسال رسالة خاصة</h3><ol><li>افتح المحادثة واختر <strong>Private Message</strong> في محرر الرسائل.</li><li>اكتب الرسالة الداخلية وتأكد من بقاء هذا الخيار محددًا قبل الإرسال.</li></ol><h3>حفظ ملاحظة للعميل</h3><ol><li>افتح محادثة العميل ووسّع <strong>User Notes</strong> في الشريط الجانبي الأيمن.</li><li>استخدم زر الإضافة واكتب الملاحظة ثم احفظها.</li><li>في محادثة لاحقة، ارجع إلى تفاصيل العميل لمراجعة الملاحظة.</li></ol><p>اجعل الملاحظات واقعية وموجزة ومفيدة لفريق الدعم. للرد على العميل استخدم Reply.</p>" },
                ko: { title: "비공개 메시지와 고객 메모 사용", content: "<p>특정 대화에 관한 팀 내부 논의에는 비공개 메시지를 사용하고, 향후 상담에 참고할 고객 정보는 User Notes에 저장하세요. 두 기능 모두 내부용이며 고객에게 답장으로 전송되지 않습니다.</p><h3>비공개 메시지 보내기</h3><ol><li>대화를 열고 작성기에서 <strong>Private Message</strong>를 선택합니다.</li><li>내부 메시지를 작성하고 보내기 전에 Private Message가 선택되어 있는지 확인합니다.</li></ol><h3>고객 메모 저장하기</h3><ol><li>고객의 대화를 열고 오른쪽 세부 정보 사이드바에서 <strong>User Notes</strong>를 펼칩니다.</li><li>추가 버튼을 눌러 메모를 입력하고 저장합니다.</li><li>다음 상담에서 고객 세부 정보를 열어 메모를 확인합니다.</li></ol><p>메모는 사실에 근거해 간결하고 팀에 유용하게 작성하세요. 고객에게 답장하려면 Reply를 사용합니다.</p>" }
              }
            }
          ]
        end
      end
    end
  end
end
