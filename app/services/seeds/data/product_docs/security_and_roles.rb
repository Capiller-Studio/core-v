# frozen_string_literal: true

module Seeds
  module Data
    module ProductDocs
      module SecurityAndRoles
        def self.category
          {
            key: :security_and_roles,
            icon_key: "shield",
            position: 9,
            translations: {
              en: {
                name: "Security, Roles & Permissions",
                description: "Review available workspace roles and configure custom permissions for teammates."
              },
              de: {
                name: "Sicherheit, Rollen & Berechtigungen",
                description: "Prüfen Sie verfügbare Rollen und konfigurieren Sie Berechtigungen für Teammitglieder."
              },
              es: {
                name: "Seguridad, Roles y Permisos",
                description: "Revise los roles disponibles y configure permisos personalizados para sus compañeros."
              },
              fr: {
                name: "Sécurité, Rôles et Permissions",
                description: "Consultez les rôles disponibles et configurez des autorisations personnalisées pour l'équipe."
              },
              "pt-BR": {
                name: "Segurança, Funções e Permissões",
                description: "Consulte as funções disponíveis e configure permissões personalizadas para a equipe."
              },
              ar: {
                name: "الأمان والأدوار والأذونات",
                description: "راجع الأدوار المتاحة واضبط أذونات مخصصة لأعضاء الفريق."
              },
              ko: {
                name: "보안, 권한 및 역할 관리",
                description: "사용 가능한 역할을 확인하고 팀원을 위한 사용자 지정 권한을 설정합니다."
              }
            }
          }
        end

        def self.articles
          [
            {
              key: :roles_and_permissions,
              position: 1,
              translations: {
                en: {
                  title: "Review Roles and Configure Permissions",
                  content: <<~HTML
                    <p>Roles determine which workspace resources teammates can access and what actions they can perform. Available permissions depend on the role and workspace configuration.</p>
                    <ol>
                      <li>Open <strong>Settings &rarr; Roles</strong> to review system-provided and custom roles.</li>
                      <li>Choose <strong>Create Role</strong> to add a custom role. Enter a name and start from a permission preset or configure the permissions matrix.</li>
                      <li>Review resource rows and action columns carefully, then save the role.</li>
                      <li>Assign the role when inviting or editing a teammate. Verify access with the appropriate account before relying on the role for sensitive workflows.</li>
                    </ol>
                    <p>System-provided roles cannot be deleted or edited in the same way as custom roles. The roles page shows which roles and actions are available in your workspace.</p>
                  HTML
                },
                de: {
                  title: "Benutzerrollen & Berechtigungen",
                  content: "<p>Rollen legen fest, auf welche Arbeitsbereichsressourcen Teammitglieder zugreifen und welche Aktionen sie ausführen können. Die verfügbaren Berechtigungen hängen von Rolle und Arbeitsbereich ab.</p><ol><li>Öffnen Sie <strong>Settings → Roles</strong>, um Systemrollen und benutzerdefinierte Rollen zu prüfen.</li><li>Wählen Sie <strong>Create Role</strong>, geben Sie einen Namen ein und starten Sie mit einer Vorlage oder der Berechtigungsmatrix.</li><li>Prüfen Sie Ressourcen und Aktionen sorgfältig und speichern Sie die Rolle.</li><li>Weisen Sie sie beim Einladen oder Bearbeiten eines Teammitglieds zu. Testen Sie den Zugriff mit einem passenden Konto, bevor Sie die Rolle für sensible Aufgaben verwenden.</li></ol><p>Systemrollen lassen sich nicht wie benutzerdefinierte Rollen bearbeiten oder löschen. Die Rollenseite zeigt verfügbare Berechtigungen.</p>"
                },
                es: {
                  title: "Roles de Usuario y Permisos",
                  content: "<p>Los roles determinan los recursos del espacio de trabajo y las acciones disponibles para cada compañero. Los permisos dependen de la configuración de su espacio.</p><ol><li>Abra <strong>Settings → Roles</strong> para revisar los roles del sistema y los personalizados.</li><li>Seleccione <strong>Create Role</strong>, escriba un nombre y elija una plantilla o configure la matriz de permisos.</li><li>Revise cuidadosamente los recursos y las acciones y guarde el rol.</li><li>Asigne el rol al invitar o editar a un compañero. Compruebe el acceso con la cuenta adecuada antes de usarlo para tareas sensibles.</li></ol><p>Los roles del sistema no se editan ni eliminan igual que los personalizados. La página muestra las opciones disponibles.</p>"
                },
                fr: {
                  title: "Rôles Utilisateurs et Permissions",
                  content: "<p>Les rôles déterminent les ressources accessibles et les actions permises aux collègues. Les autorisations disponibles dépendent de l'espace de travail.</p><ol><li>Ouvrez <strong>Settings → Roles</strong> pour consulter les rôles système et personnalisés.</li><li>Choisissez <strong>Create Role</strong>, saisissez un nom et partez d'un modèle ou configurez la matrice des autorisations.</li><li>Vérifiez les ressources et actions, puis enregistrez.</li><li>Attribuez le rôle à l'invitation ou à la modification d'un collègue. Testez l'accès avec le compte approprié avant de l'utiliser pour une tâche sensible.</li></ol><p>Les rôles système ne se modifient ni ne se suppriment comme les rôles personnalisés. La page indique les options disponibles.</p>"
                },
                "pt-BR": {
                  title: "Funções de Usuário e Permissões",
                  content: "<p>As funções definem quais recursos do espaço de trabalho cada colega pode acessar e quais ações pode executar. As permissões disponíveis dependem da configuração da conta.</p><ol><li>Abra <strong>Settings → Roles</strong> para revisar funções do sistema e personalizadas.</li><li>Selecione <strong>Create Role</strong>, informe um nome e use uma predefinição ou configure a matriz de permissões.</li><li>Revise os recursos e as ações com atenção e salve a função.</li><li>Atribua-a ao convidar ou editar um colega. Teste o acesso com a conta adequada antes de usar a função em tarefas sensíveis.</li></ol><p>Funções do sistema não podem ser editadas ou excluídas como as personalizadas. A página mostra as opções disponíveis.</p>"
                },
                ar: {
                  title: "أدوار المستخدمين والأذونات",
                  content: "<p>تحدد الأدوار موارد مساحة العمل والإجراءات التي يمكن لكل زميل الوصول إليها. وتعتمد الأذونات المتاحة على إعداد مساحة العمل.</p><ol><li>افتح <strong>Settings → Roles</strong> لمراجعة أدوار النظام والأدوار المخصصة.</li><li>اختر <strong>Create Role</strong> وأدخل اسمًا، ثم استخدم إعدادًا مسبقًا أو اضبط مصفوفة الأذونات.</li><li>راجع الموارد والإجراءات بعناية ثم احفظ الدور.</li><li>عيّن الدور عند دعوة زميل أو تعديل حسابه. اختبر الوصول بالحساب المناسب قبل استخدام الدور في مهام حساسة.</li></ol><p>لا تُعدّل أدوار النظام أو تُحذف بالطريقة نفسها التي تُدار بها الأدوار المخصصة. تعرض صفحة الأدوار الخيارات المتاحة.</p>"
                },
                ko: {
                  title: "사용자 역할 및 세부 권한 설정",
                  content: "<p>역할은 팀원이 접근할 수 있는 워크스페이스 리소스와 수행 가능한 작업을 결정합니다. 권한은 워크스페이스 설정에 따라 달라집니다.</p><ol><li><strong>Settings → Roles</strong>를 열어 기본 역할과 사용자 지정 역할을 확인합니다.</li><li><strong>Create Role</strong>을 선택하고 이름을 입력한 뒤 프리셋을 사용하거나 권한 매트릭스를 구성합니다.</li><li>리소스와 작업 권한을 꼼꼼히 검토하고 저장합니다.</li><li>팀원을 초대하거나 수정할 때 역할을 지정합니다. 민감한 업무에 적용하기 전에 해당 계정으로 접근 권한을 확인하세요.</li></ol><p>기본 역할은 사용자 지정 역할과 동일한 방식으로 수정하거나 삭제할 수 없습니다. 역할 화면에서 사용할 수 있는 권한을 확인하세요.</p>"
                }
              }
            }
          ]
        end
      end
    end
  end
end
