# frozen_string_literal: true

module Seeds
  module Data
    module ProductDocs
      module RoutingAndAvailability
        def self.category
          {
            key: :routing_and_availability,
            icon_key: "clock",
            position: 13,
            show_in_navbar: true,
            translations: {
              en: { name: "Routing & Availability", description: "Set assignment strategies, business-hour schedules, and service targets for inboxes." },
              de: { name: "Zuweisung & Verfügbarkeit", description: "Konfigurieren Sie Zuweisungsstrategien, Geschäftszeiten und Serviceziele." },
              es: { name: "Asignación y disponibilidad", description: "Configure estrategias de asignación, horarios comerciales y objetivos de servicio." },
              fr: { name: "Attribution et disponibilité", description: "Configurez les stratégies d'attribution, les horaires ouvrés et les objectifs de service." },
              "pt-BR": { name: "Atribuição e disponibilidade", description: "Configure estratégias de atribuição, horários comerciais e metas de serviço." },
              ar: { name: "التعيين والتوفر", description: "اضبط استراتيجيات التعيين وجداول ساعات العمل وأهداف الخدمة." },
              ko: { name: "할당 및 업무 시간", description: "할당 전략, 업무 시간 일정 및 서비스 목표를 설정합니다." }
            }
          }
        end

        def self.articles
          [
            {
              key: :assignment_policy_setup,
              position: 1,
              translations: {
                en: {
                  title: "Configure an Assignment Policy",
                  content: <<~HTML
                    <p>An assignment policy controls how eligible conversations are distributed across teammates. The policy form provides manual, round-robin, load-balanced, and skills-based strategies; options shown can depend on the selected strategy.</p>
                    <ol>
                      <li>Open <strong>Settings &rarr; Assignment Policies</strong> and create a policy.</li>
                      <li>Enter a name, select the assignment strategy, and review the capacity setting.</li>
                      <li>Select the inboxes where the policy applies. If the policy should honor a schedule, enable business hours and select a schedule.</li>
                      <li>Review the available policy options, such as skill consideration or reassignment behavior, and save.</li>
                      <li>Open the relevant inbox or channel settings and select the assignment policy where that control is available. Auto-assignment must also be enabled for inboxes that expose that setting.</li>
                    </ol>
                    <p>If a conversation is not assigned as expected, check the policy's inbox selection, strategy, capacity, teammate/team eligibility, business-hours setting, and the inbox's auto-assignment setting.</p>
                  HTML
                },
                de: { title: "Zuweisungsrichtlinie konfigurieren", content: "<p>Mit einer Zuweisungsrichtlinie werden geeignete Gespräche nach einer ausgewählten Strategie an Teammitglieder verteilt.</p><ol><li>Öffnen Sie <strong>Einstellungen &rarr; Assignment Policies</strong> und erstellen Sie eine Richtlinie.</li><li>Geben Sie einen Namen ein und wählen Sie manuelle Zuweisung, Round Robin, Lastenausgleich oder kompetenzbasierte Zuweisung.</li><li>Legen Sie Kapazität und Postfächer fest, für die die Richtlinie gilt.</li><li>Aktivieren Sie bei Bedarf Geschäftszeiten und wählen Sie einen Zeitplan. Prüfen Sie weitere Optionen der gewählten Strategie und speichern Sie.</li><li>Wählen Sie die Richtlinie in den passenden Postfach- oder Kanaleinstellungen aus und aktivieren Sie dort gegebenenfalls die automatische Zuweisung.</li></ol><p>Werden Gespräche nicht verteilt, prüfen Sie Postfachauswahl, Kapazität, Team- und Mitarbeiterberechtigungen, Geschäftszeiten sowie die Auto-Zuweisung im Postfach.</p>" },
                es: { title: "Configurar una política de asignación", content: "<p>Una política distribuye conversaciones aptas entre compañeros mediante una estrategia elegida.</p><ol><li>Abra <strong>Configuración &rarr; Assignment Policies</strong> y cree una política.</li><li>Escriba un nombre y elija asignación manual, round robin, equilibrada o basada en habilidades.</li><li>Defina la capacidad y seleccione las bandejas a las que se aplica.</li><li>Si corresponde, active el horario comercial y seleccione un calendario. Revise las opciones de la estrategia y guarde.</li><li>Seleccione la política en los ajustes de la bandeja o canal correspondiente y active allí la asignación automática si está disponible.</li></ol><p>Si no se asignan conversaciones, revise las bandejas seleccionadas, la capacidad, la elegibilidad de equipos y compañeros, el horario y la asignación automática de la bandeja.</p>" },
                fr: { title: "Configurer une politique d'attribution", content: "<p>Une politique répartit les conversations admissibles entre les collègues selon une stratégie choisie.</p><ol><li>Ouvrez <strong>Paramètres &rarr; Assignment Policies</strong> et créez une politique.</li><li>Saisissez un nom et choisissez l'attribution manuelle, round robin, équilibrée ou par compétences.</li><li>Définissez la capacité et sélectionnez les boîtes concernées.</li><li>Si nécessaire, activez les heures ouvrées et choisissez un horaire. Vérifiez les options de la stratégie puis enregistrez.</li><li>Sélectionnez la politique dans les paramètres de la boîte ou du canal concerné et activez l'attribution automatique si cette option est proposée.</li></ol><p>En cas de problème, vérifiez les boîtes sélectionnées, la capacité, l'éligibilité des équipes et collègues, les heures ouvrées et l'option d'attribution automatique.</p>" },
                "pt-BR": { title: "Configurar uma política de atribuição", content: "<p>Uma política distribui conversas elegíveis entre colegas de acordo com uma estratégia escolhida.</p><ol><li>Abra <strong>Configurações &rarr; Assignment Policies</strong> e crie uma política.</li><li>Informe um nome e escolha atribuição manual, round robin, balanceada ou baseada em habilidades.</li><li>Defina a capacidade e selecione as caixas às quais ela se aplica.</li><li>Se necessário, ative o horário comercial e escolha uma agenda. Revise as opções da estratégia e salve.</li><li>Selecione a política nas configurações da caixa ou canal correspondente e ative a atribuição automática, se disponível.</li></ol><p>Se as conversas não forem atribuídas, confira as caixas selecionadas, capacidade, elegibilidade de equipes e colegas, horário comercial e atribuição automática da caixa.</p>" },
                ar: { title: "إعداد سياسة التعيين", content: "<p>توزع سياسة التعيين المحادثات المؤهلة على الزملاء وفق استراتيجية محددة.</p><ol><li>افتح <strong>الإعدادات &rarr; Assignment Policies</strong> وأنشئ سياسة.</li><li>أدخل اسمًا واختر التعيين اليدوي أو التناوبي أو المتوازن أو القائم على المهارات.</li><li>حدد السعة وصناديق الوارد التي تنطبق عليها السياسة.</li><li>فعّل ساعات العمل عند الحاجة واختر جدولًا، ثم راجع خيارات الاستراتيجية واحفظ.</li><li>حدد السياسة في إعدادات صندوق الوارد أو القناة المناسبة، وفعّل التعيين التلقائي هناك إذا كان الخيار متاحًا.</li></ol><p>إذا لم توزّع المحادثات، فتحقق من الصناديق والسعة وأهلية الفرق والزملاء وساعات العمل وخيار التعيين التلقائي.</p>" },
                ko: { title: "할당 정책 설정", content: "<p>할당 정책은 선택한 전략에 따라 대상 대화를 팀원에게 배분합니다.</p><ol><li><strong>설정 &rarr; Assignment Policies</strong>를 열고 정책을 만듭니다.</li><li>이름을 입력하고 수동, 라운드 로빈, 부하 분산 또는 기술 기반 전략을 선택합니다.</li><li>처리 용량과 정책을 적용할 받은 편지함을 지정합니다.</li><li>필요하면 업무 시간을 켜고 일정을 선택합니다. 전략별 옵션을 검토하고 저장합니다.</li><li>해당 받은 편지함이나 채널 설정에서 정책을 선택하고, 제공되는 경우 자동 할당도 활성화합니다.</li></ol><p>대화가 할당되지 않으면 받은 편지함 선택, 용량, 팀원 자격, 업무 시간 및 받은 편지함의 자동 할당 설정을 확인하세요.</p>" }
              }
            },
            {
              key: :business_hours_setup,
              position: 2,
              translations: {
                en: {
                  title: "Create Business Hours and Set a Time Zone",
                  content: <<~HTML
                    <p>A business-hours group stores weekly availability in its own time zone. A schedule does not affect a channel until you select it in that channel's inbox settings or in a policy that supports business hours.</p>
                    <ol>
                      <li>Open <strong>Settings &rarr; Business Hours</strong> and create a group.</li>
                      <li>Enter a name and choose the schedule's time zone. Use the time zone in which the working hours should be interpreted.</li>
                      <li>For each day, turn the day on or off and add one or more time ranges. Use additional ranges for breaks between working periods.</li>
                      <li>Save the schedule, then edit each applicable channel and choose it in <strong>Inbox Settings &rarr; Business Hours</strong>. For assignment or SLA policies, select it in the policy settings as applicable.</li>
                    </ol>
                    <p>When coverage looks wrong, verify the schedule's time zone, enabled days, saved time ranges, and the schedule selected on the inbox or policy. Daylight-saving changes are applied according to the selected time zone.</p>
                  HTML
                },
                de: { title: "Geschäftszeiten erstellen und Zeitzone festlegen", content: "<p>Eine Geschäftszeitengruppe legt wöchentliche Verfügbarkeit in ihrer eigenen Zeitzone fest. Sie wirkt erst, wenn sie einem Postfach oder einer unterstützenden Richtlinie zugewiesen ist.</p><ol><li>Öffnen Sie <strong>Einstellungen &rarr; Business Hours</strong> und erstellen Sie eine Gruppe.</li><li>Geben Sie einen Namen ein und wählen Sie die Zeitzone, in der die Arbeitszeiten gelten sollen.</li><li>Aktivieren Sie jeden gewünschten Wochentag und fügen Sie ein oder mehrere Zeitfenster hinzu. Nutzen Sie mehrere Fenster für Pausen.</li><li>Speichern Sie den Zeitplan und wählen Sie ihn in den Postfach- oder Kanaleinstellungen unter <strong>Inbox Settings &rarr; Business Hours</strong> aus. Weisen Sie ihn bei Bedarf auch einer Richtlinie zu.</li></ol><p>Prüfen Sie bei falscher Abdeckung Zeitzone, aktive Tage, Zeitfenster und die Zuordnung zum Postfach. Sommerzeit richtet sich nach der gewählten Zeitzone.</p>" },
                es: { title: "Crear horarios comerciales y elegir una zona horaria", content: "<p>Un grupo de horario define la disponibilidad semanal en su propia zona horaria. No se aplica hasta que se selecciona en una bandeja o política compatible.</p><ol><li>Abra <strong>Configuración &rarr; Business Hours</strong> y cree un grupo.</li><li>Escriba un nombre y elija la zona horaria en la que deben interpretarse las horas.</li><li>Active cada día necesario y añada uno o varios intervalos. Use varios intervalos para separar los descansos.</li><li>Guarde el horario y selecciónelo en la bandeja o canal en <strong>Inbox Settings &rarr; Business Hours</strong>. Asígnelo también a una política si corresponde.</li></ol><p>Si la cobertura no coincide, revise zona horaria, días activos, intervalos y bandeja o política vinculada. El cambio de horario estacional sigue la zona elegida.</p>" },
                fr: { title: "Créer des heures ouvrées et choisir un fuseau horaire", content: "<p>Un groupe d'heures ouvrées définit la disponibilité hebdomadaire dans son fuseau horaire. Il ne s'applique qu'après avoir été sélectionné dans une boîte ou une politique compatible.</p><ol><li>Ouvrez <strong>Paramètres &rarr; Business Hours</strong> et créez un groupe.</li><li>Saisissez un nom et choisissez le fuseau horaire de référence.</li><li>Activez chaque jour souhaité et ajoutez un ou plusieurs créneaux. Créez plusieurs créneaux pour séparer les pauses.</li><li>Enregistrez l'horaire et sélectionnez-le dans la boîte ou le canal sous <strong>Inbox Settings &rarr; Business Hours</strong>. Associez-le aussi à une politique si nécessaire.</li></ol><p>En cas d'écart, vérifiez le fuseau, les jours actifs, les créneaux et l'association à la boîte ou à la politique. Le changement d'heure suit le fuseau choisi.</p>" },
                "pt-BR": { title: "Criar horário comercial e definir o fuso horário", content: "<p>Um grupo de horário comercial define a disponibilidade semanal no próprio fuso. Ele só se aplica depois de ser selecionado em uma caixa ou política compatível.</p><ol><li>Abra <strong>Configurações &rarr; Business Hours</strong> e crie um grupo.</li><li>Informe um nome e escolha o fuso horário em que os horários devem ser considerados.</li><li>Ative cada dia desejado e adicione um ou mais intervalos. Use vários intervalos para separar pausas.</li><li>Salve e selecione o horário na caixa ou canal em <strong>Inbox Settings &rarr; Business Hours</strong>. Associe-o também a uma política, se aplicável.</li></ol><p>Se a cobertura estiver incorreta, confira o fuso, os dias ativos, os intervalos e a caixa ou política vinculada. O horário de verão segue o fuso selecionado.</p>" },
                ar: { title: "إنشاء ساعات العمل وتحديد المنطقة الزمنية", content: "<p>تحدد مجموعة ساعات العمل التوفر الأسبوعي وفق منطقتها الزمنية. ولا تُطبق حتى تختارها في صندوق وارد أو سياسة تدعمها.</p><ol><li>افتح <strong>الإعدادات &rarr; Business Hours</strong> وأنشئ مجموعة.</li><li>أدخل اسمًا وحدد المنطقة الزمنية التي تُفسر بها ساعات العمل.</li><li>فعّل كل يوم مطلوب وأضف فترة أو أكثر. استخدم فترات متعددة للفصل بين أوقات العمل والاستراحة.</li><li>احفظ الجدول وحدده في إعدادات الصندوق أو القناة ضمن <strong>Inbox Settings &rarr; Business Hours</strong>، واربطه بسياسة عند الحاجة.</li></ol><p>إذا كان التوفر غير صحيح، فتحقق من المنطقة الزمنية والأيام والفترات والصندوق أو السياسة المرتبطة. يتبع التوقيت الصيفي المنطقة الزمنية المختارة.</p>" },
                ko: { title: "업무 시간 및 시간대 설정", content: "<p>업무 시간 그룹은 해당 시간대 기준으로 주간 응답 가능 시간을 정합니다. 지원되는 받은 편지함이나 정책에서 그룹을 선택해야 적용됩니다.</p><ol><li><strong>설정 &rarr; Business Hours</strong>를 열고 그룹을 만듭니다.</li><li>이름을 입력하고 업무 시간에 적용할 시간대를 선택합니다.</li><li>운영할 요일을 켜고 시간 구간을 추가합니다. 휴식 시간이 있으면 구간을 나눠 입력합니다.</li><li>저장한 뒤 받은 편지함이나 채널의 <strong>Inbox Settings &rarr; Business Hours</strong>에서 일정을 선택합니다. 필요한 정책에도 연결합니다.</li></ol><p>응답 시간이 맞지 않으면 시간대, 활성 요일, 구간, 연결된 받은 편지함이나 정책을 확인하세요. 서머타임은 선택한 시간대 규칙을 따릅니다.</p>" }
              }
            }
          ]
        end
      end
    end
  end
end
