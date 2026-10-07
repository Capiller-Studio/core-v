# frozen_string_literal: true

module Seeds
  module Data
    module ProductDocs
      module TeamsAndTeammates
        def self.category
          {
            key: :teams_and_teammates,
            icon_key: "users",
            position: 12,
            show_in_navbar: true,
            translations: {
              en: { name: "Teams & Teammates", description: "Invite workspace members, manage roles, and organize people into teams." },
              de: { name: "Teams & Teammitglieder", description: "Laden Sie Mitglieder ein, verwalten Sie Rollen und organisieren Sie Teams." },
              es: { name: "Equipos y compañeros", description: "Invite miembros, gestione roles y organice equipos." },
              fr: { name: "Équipes et collègues", description: "Invitez des membres, gérez les rôles et organisez les équipes." },
              "pt-BR": { name: "Equipes e colegas", description: "Convide membros, gerencie funções e organize equipes." },
              ar: { name: "الفرق والزملاء", description: "ادعُ أعضاء مساحة العمل وأدر الأدوار ونظّم الفرق." },
              ko: { name: "팀 및 팀원", description: "워크스페이스 멤버를 초대하고 역할을 관리하며 팀을 구성합니다." }
            }
          }
        end

        def self.articles
          [
            {
              key: :invite_teammates_and_roles,
              position: 1,
              translations: {
                en: {
                  title: "Invite Teammates and Manage Their Roles",
                  content: <<~HTML
                    <p>Workspace members are managed separately from conversation channels. Invite only people who need access and assign each person the role that matches their responsibilities.</p>
                    <ol>
                      <li>Open <strong>Settings &rarr; Users (Teammates)</strong> and choose <strong>Invite member</strong>.</li>
                      <li>Enter the teammate's email address and complete the invitation form.</li>
                      <li>Choose an available role and send the invitation. The invited person must accept it to join the workspace.</li>
                      <li>Use the member list to review a person's role or remove their access when they leave the team.</li>
                    </ol>
                    <p>Before changing roles, review <strong>Settings &rarr; Roles</strong> to understand the permissions assigned to each role. Do not assume that similarly named roles have identical access.</p>
                    <h3>Check the invitation</h3>
                    <p>Open the <strong>Invitations</strong> view from the Users page to review pending invitations. If the invitation is not received, confirm the email address and ask the recipient to check spam or filtering rules.</p>
                  HTML
                },
                de: { title: "Teammitglieder einladen und Rollen verwalten", content: "<p>Laden Sie nur Personen ein, die Zugriff auf den Arbeitsbereich benötigen, und vergeben Sie die passende Rolle.</p><ol><li>Öffnen Sie <strong>Einstellungen &rarr; Users (Teammates)</strong> und wählen Sie <strong>Invite member</strong>.</li><li>Geben Sie die E-Mail-Adresse ein, wählen Sie eine verfügbare Rolle und senden Sie die Einladung.</li><li>Die eingeladene Person muss die Einladung annehmen. Prüfen Sie den Status in der Ansicht <strong>Invitations</strong>.</li><li>Öffnen Sie den Eintrag eines Mitglieds, um die Rolle zu überprüfen oder den Zugriff zu entfernen.</li></ol><p>Lesen Sie vor einer Rollenänderung unter <strong>Einstellungen &rarr; Roles</strong> die Berechtigungen. Bei fehlender Einladung prüfen Sie die Adresse sowie Spam- und Filterregeln.</p>" },
                es: { title: "Invitar compañeros y administrar roles", content: "<p>Invite solo a las personas que necesiten acceso al espacio de trabajo y asigne el rol adecuado a sus responsabilidades.</p><ol><li>Abra <strong>Configuración &rarr; Users (Teammates)</strong> y seleccione <strong>Invite member</strong>.</li><li>Introduzca el correo electrónico, elija un rol disponible y envíe la invitación.</li><li>La persona debe aceptar la invitación. Consulte su estado en <strong>Invitations</strong>.</li><li>Abra el registro de un miembro para revisar su rol o retirar su acceso.</li></ol><p>Antes de cambiar un rol, consulte sus permisos en <strong>Configuración &rarr; Roles</strong>. Si no llega la invitación, confirme el correo y revise spam y filtros.</p>" },
                fr: { title: "Inviter des collègues et gérer leurs rôles", content: "<p>Invitez uniquement les personnes qui ont besoin d'accéder à l'espace de travail et attribuez un rôle adapté à leurs responsabilités.</p><ol><li>Ouvrez <strong>Paramètres &rarr; Users (Teammates)</strong>, puis choisissez <strong>Invite member</strong>.</li><li>Saisissez l'adresse e-mail, sélectionnez un rôle disponible et envoyez l'invitation.</li><li>La personne doit accepter l'invitation. Consultez son état dans <strong>Invitations</strong>.</li><li>Ouvrez la fiche d'un membre pour vérifier son rôle ou supprimer son accès.</li></ol><p>Avant de modifier un rôle, consultez ses autorisations dans <strong>Paramètres &rarr; Roles</strong>. Si l'invitation n'arrive pas, vérifiez l'adresse, les courriers indésirables et les filtres.</p>" },
                "pt-BR": { title: "Convidar colegas e gerenciar funções", content: "<p>Convide apenas quem precisa acessar o workspace e atribua uma função compatível com as responsabilidades da pessoa.</p><ol><li>Abra <strong>Configurações &rarr; Users (Teammates)</strong> e selecione <strong>Invite member</strong>.</li><li>Informe o e-mail, escolha uma função disponível e envie o convite.</li><li>A pessoa precisa aceitar o convite. Confira o status em <strong>Invitations</strong>.</li><li>Abra o cadastro de um membro para revisar sua função ou remover o acesso.</li></ol><p>Antes de alterar uma função, consulte as permissões em <strong>Configurações &rarr; Roles</strong>. Se o convite não chegar, confirme o endereço e verifique spam e filtros.</p>" },
                ar: { title: "دعوة الزملاء وإدارة أدوارهم", content: "<p>ادعُ الأشخاص الذين يحتاجون إلى الوصول لمساحة العمل فقط، وحدد لكل شخص دورًا يناسب مسؤولياته.</p><ol><li>افتح <strong>الإعدادات &rarr; Users (Teammates)</strong> واختر <strong>Invite member</strong>.</li><li>أدخل البريد الإلكتروني وحدد دورًا متاحًا ثم أرسل الدعوة.</li><li>يجب على المدعو قبول الدعوة. راجع حالتها في <strong>Invitations</strong>.</li><li>افتح سجل العضو لمراجعة دوره أو إزالة وصوله.</li></ol><p>قبل تغيير الدور، راجع صلاحياته في <strong>الإعدادات &rarr; Roles</strong>. إذا لم تصل الدعوة، تحقق من البريد ومجلد الرسائل غير المرغوب فيها وقواعد التصفية.</p>" },
                ko: { title: "팀원 초대 및 역할 관리", content: "<p>워크스페이스 접근이 필요한 사람만 초대하고 담당 업무에 맞는 역할을 지정하세요.</p><ol><li><strong>설정 &rarr; Users (Teammates)</strong>를 열고 <strong>Invite member</strong>를 선택합니다.</li><li>이메일을 입력하고 사용 가능한 역할을 선택해 초대장을 보냅니다.</li><li>초대받은 사람이 수락해야 참여할 수 있습니다. <strong>Invitations</strong>에서 상태를 확인하세요.</li><li>멤버 항목을 열어 역할을 확인하거나 접근 권한을 제거합니다.</li></ol><p>역할을 변경하기 전에 <strong>설정 &rarr; Roles</strong>에서 권한을 확인하세요. 초대장이 도착하지 않으면 주소와 스팸함 및 필터 규칙을 살펴보세요.</p>" }
              }
            },
            {
              key: :create_and_manage_teams,
              position: 2,
              translations: {
                en: {
                  title: "Create Teams and Add Teammates",
                  content: <<~HTML
                    <p>Teams group workspace members for assignment and collaboration. Create a team after the members who need to belong to it have access to the workspace.</p>
                    <ol>
                      <li>Open <strong>Settings &rarr; Teams</strong> and choose <strong>New team</strong>.</li>
                      <li>Enter a team name and any description, then save.</li>
                      <li>Open the team settings or <strong>Add teammates</strong> action, select the members, and save the membership changes.</li>
                      <li>When configuring an inbox or assignment policy, select this team if it should collaborate on or receive conversations for that workflow.</li>
                    </ol>
                    <p>Team membership and channel access are separate controls. Review the inbox's collaborator and team settings to make sure members can see the conversations they need.</p>
                  HTML
                },
                de: { title: "Teams erstellen und Teammitglieder hinzufügen", content: "<p>Teams bündeln Mitglieder für Zusammenarbeit und Zuweisungen. Die Teammitgliedschaft ersetzt nicht die Zugriffsrechte auf ein Postfach.</p><ol><li>Öffnen Sie <strong>Einstellungen &rarr; Teams</strong> und wählen Sie <strong>New team</strong>.</li><li>Geben Sie einen Namen und bei Bedarf eine Beschreibung ein und speichern Sie.</li><li>Öffnen Sie die Teameinstellungen oder wählen Sie <strong>Add teammates</strong>, markieren Sie die gewünschten Mitglieder und speichern Sie.</li><li>Wählen Sie das Team in den Postfach- oder Zuweisungsrichtlinien aus, wenn es Gespräche bearbeiten soll.</li></ol><p>Prüfen Sie zusätzlich die Mitarbeiter- und Teamzuweisungen des Postfachs, damit Mitglieder die benötigten Gespräche sehen können.</p>" },
                es: { title: "Crear equipos y añadir compañeros", content: "<p>Los equipos agrupan compañeros para colaborar y recibir asignaciones. Ser miembro de un equipo no concede por sí solo acceso a una bandeja.</p><ol><li>Abra <strong>Configuración &rarr; Teams</strong> y seleccione <strong>New team</strong>.</li><li>Escriba un nombre y, si lo desea, una descripción; después guarde.</li><li>Abra la configuración del equipo o use <strong>Add teammates</strong>, seleccione los miembros y guarde los cambios.</li><li>Seleccione el equipo en los ajustes de la bandeja o política de asignación si debe colaborar en esas conversaciones.</li></ol><p>Revise también los colaboradores y equipos autorizados en la bandeja para asegurar que sus miembros puedan ver las conversaciones necesarias.</p>" },
                fr: { title: "Créer des équipes et ajouter des collègues", content: "<p>Les équipes regroupent des collègues pour collaborer et recevoir des attributions. L'appartenance à une équipe ne donne pas automatiquement accès à une boîte.</p><ol><li>Ouvrez <strong>Paramètres &rarr; Teams</strong> et choisissez <strong>New team</strong>.</li><li>Saisissez un nom et, si besoin, une description, puis enregistrez.</li><li>Ouvrez les paramètres de l'équipe ou utilisez <strong>Add teammates</strong>, sélectionnez les membres et enregistrez.</li><li>Sélectionnez l'équipe dans les paramètres de la boîte ou de la politique d'attribution si elle doit traiter ces conversations.</li></ol><p>Vérifiez également les collègues et équipes autorisés dans la boîte afin qu'ils puissent consulter les conversations nécessaires.</p>" },
                "pt-BR": { title: "Criar equipes e adicionar colegas", content: "<p>As equipes agrupam colegas para colaboração e atribuições. Fazer parte de uma equipe não concede automaticamente acesso a uma caixa de entrada.</p><ol><li>Abra <strong>Configurações &rarr; Teams</strong> e escolha <strong>New team</strong>.</li><li>Informe um nome e, se quiser, uma descrição; depois salve.</li><li>Abra as configurações da equipe ou use <strong>Add teammates</strong>, selecione os membros e salve.</li><li>Selecione a equipe na caixa ou política de atribuição se ela deve colaborar nessas conversas.</li></ol><p>Confira também os colaboradores e equipes autorizados na caixa para que os membros possam visualizar as conversas necessárias.</p>" },
                ar: { title: "إنشاء الفرق وإضافة الزملاء", content: "<p>تجمع الفرق الزملاء للتعاون واستلام المحادثات. ولا تمنح عضوية الفريق وحدها صلاحية الوصول إلى صندوق وارد.</p><ol><li>افتح <strong>الإعدادات &rarr; Teams</strong> واختر <strong>New team</strong>.</li><li>أدخل اسمًا ووصفًا اختياريًا ثم احفظ.</li><li>افتح إعدادات الفريق أو استخدم <strong>Add teammates</strong>، وحدد الأعضاء ثم احفظ التغييرات.</li><li>حدد الفريق في إعدادات صندوق الوارد أو سياسة التعيين إذا كان سيعالج تلك المحادثات.</li></ol><p>راجع أيضًا الفرق والزملاء المسموح لهم في الصندوق حتى يتمكن الأعضاء من رؤية المحادثات المطلوبة.</p>" },
                ko: { title: "팀 만들기 및 팀원 추가", content: "<p>팀은 협업과 대화 할당을 위해 팀원을 묶습니다. 팀에 속해도 받은 편지함 접근 권한이 자동으로 생기지는 않습니다.</p><ol><li><strong>설정 &rarr; Teams</strong>를 열고 <strong>New team</strong>을 선택합니다.</li><li>팀 이름과 필요하면 설명을 입력한 뒤 저장합니다.</li><li>팀 설정을 열거나 <strong>Add teammates</strong>를 선택하고 멤버를 지정해 저장합니다.</li><li>팀이 대화를 함께 처리해야 한다면 받은 편지함이나 할당 정책 설정에서 팀을 선택합니다.</li></ol><p>멤버가 필요한 대화를 볼 수 있도록 받은 편지함의 팀 및 협업자 권한도 확인하세요.</p>" }
              }
            }
          ]
        end
      end
    end
  end
end
