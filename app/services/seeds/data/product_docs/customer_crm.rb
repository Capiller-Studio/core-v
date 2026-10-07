# frozen_string_literal: true

module Seeds
  module Data
    module ProductDocs
      module CustomerCrm
        def self.category
          {
            key: :customer_crm,
            icon_key: "users",
            position: 6,
            translations: {
              en: {
                name: "Customer CRM & Contacts",
                description: "Review customer profiles, connected identities, linked inboxes, internal customer notes, and customer or conversation custom fields."
              },
              de: {
                name: "Kunden-CRM & Kontakte",
                description: "Prüfen Sie Kundenprofile, Kanalidentitäten, verknüpfte Postfächer, interne Kundennotizen und benutzerdefinierte Felder."
              },
              es: {
                name: "CRM de Clientes y Contactos",
                description: "Consulte perfiles, identidades de canal, bandejas vinculadas, notas internas y campos personalizados de clientes o conversaciones."
              },
              fr: {
                name: "CRM Clients et Contacts",
                description: "Consultez les profils, identités de canal, boîtes liées, notes internes et champs personnalisés des clients ou conversations."
              },
              "pt-BR": {
                name: "CRM de Clientes e Contatos",
                description: "Consulte perfis, identidades de canal, caixas vinculadas, notas internas e campos personalizados de clientes ou conversas."
              },
              ar: {
                name: "إدارة علاقات العملاء (CRM) وجهات الاتصال",
                description: "مراجعة ملفات العملاء وهويات القنوات وصناديق الوارد المرتبطة والملاحظات الداخلية والحقول المخصصة للعملاء أو المحادثات."
              },
              ko: {
                name: "고객 관리 (CRM) 및 연락처",
                description: "고객 프로필, 채널 ID, 연결된 받은 편지함, 내부 메모와 고객·대화 사용자 지정 필드를 확인하고 관리합니다."
              }
            }
          }
        end

        def self.articles
          [
            {
              key: :customer_profiles_and_timeline,
              position: 1,
              translations: {
                en: {
                  title: "Customer Profiles & Interaction Timelines",
                  content: <<~HTML
                    <p>Customer records bring together the contact details and channel identities Deskbolic has associated with a person. The profile shows linked inboxes and a conversation count; it is not a complete transcript timeline.</p>
                    <h3>Find and review a customer</h3>
                    <ol>
                      <li>Open <strong>Customers</strong> from the dashboard settings navigation.</li>
                      <li>Search by customer name or contact value. Use the channel filter to narrow the list, or sort by newest, oldest, or name.</li>
                      <li>Choose <strong>Show</strong> to open the profile. Review customer details, connected identities, linked inboxes, conversation count, and last activity.</li>
                      <li>Choose <strong>Edit Customer</strong> when you have permission and need to update profile information.</li>
                    </ol>
                    <h3>Review a profile from a conversation</h3>
                    <p>Open a conversation and use the customer details sidebar to review available profile information, customer notes, and conversation-specific information. Use User Notes for concise internal context that should help teammates in future conversations.</p>
                    <p>Channel identity linking depends on the identifiers available from each channel. If an expected conversation or identity is missing, verify that it belongs to the same customer record before editing contact data.</p>
                  HTML
                },
                de: {
                  title: "Kundenprofile & Interaktionsverlauf",
                  content: "<p>Kundenprofile zeigen Kontaktinformationen und Kanalidentitäten, die Deskbolic einer Person zugeordnet hat. Sie zeigen verknüpfte Postfächer, Konversationsanzahl und letzte Aktivität.</p><h3>Kundenprofil finden</h3><ol><li>Öffnen Sie <strong>Customers</strong> in der Dashboard-Navigation.</li><li>Suchen Sie nach Name oder Kontaktwert. Filtern Sie nach Kanal oder sortieren Sie nach neu, alt oder Name.</li><li>Wählen Sie <strong>Show</strong>, um Details, verbundene Identitäten und Postfächer sowie Aktivität zu prüfen.</li><li>Wählen Sie <strong>Edit Customer</strong>, wenn Sie die Berechtigung haben und Profildaten ändern müssen.</li></ol><p>In einer Konversation finden Sie weitere verfügbare Kundendaten und User Notes in der rechten Seitenleiste. Die Zuordnung von Kanalidentitäten hängt von den Identifikatoren des jeweiligen Kanals ab.</p>"
                },
                es: {
                  title: "Perfiles de Clientes y Línea de Tiempo",
                  content: "<p>El perfil muestra la información de contacto y las identidades de canal que Deskbolic ha asociado a una persona. También muestra bandejas vinculadas, cantidad de conversaciones y actividad reciente.</p><h3>Buscar un perfil</h3><ol><li>Abra <strong>Customers</strong> en la navegación del panel.</li><li>Busque por nombre o dato de contacto. Filtre por canal o ordene por fecha o nombre.</li><li>Seleccione <strong>Show</strong> para revisar detalles, identidades, bandejas vinculadas y actividad.</li><li>Si tiene permiso, seleccione <strong>Edit Customer</strong> para cambiar los datos del perfil.</li></ol><p>En una conversación, consulte los datos disponibles y User Notes en la barra lateral derecha. La vinculación de identidades depende de los identificadores que proporciona cada canal.</p>"
                },
                fr: {
                  title: "Profils Clients et Historique des Échanges",
                  content: "<p>Le profil présente les coordonnées et identités de canal que Deskbolic a associées à une personne. Il affiche les boîtes liées, le nombre de conversations et la dernière activité.</p><h3>Rechercher un profil</h3><ol><li>Ouvrez <strong>Customers</strong> dans la navigation du tableau de bord.</li><li>Recherchez par nom ou coordonnée. Filtrez par canal ou triez par date ou nom.</li><li>Choisissez <strong>Show</strong> pour consulter les détails, identités, boîtes liées et l'activité.</li><li>Si vous en avez l'autorisation, choisissez <strong>Edit Customer</strong> pour modifier le profil.</li></ol><p>Dans une conversation, consultez les informations disponibles et User Notes dans le panneau latéral droit. Le rapprochement des identités dépend des identifiants fournis par chaque canal.</p>"
                },
                "pt-BR": {
                  title: "Perfis de Clientes e Linha do Tempo",
                  content: "<p>O perfil mostra os dados de contato e as identidades de canal que o Deskbolic associou à pessoa. Ele exibe caixas vinculadas, quantidade de conversas e atividade recente.</p><h3>Encontrar um perfil</h3><ol><li>Abra <strong>Customers</strong> na navegação do painel.</li><li>Pesquise por nome ou contato. Filtre por canal ou ordene por data ou nome.</li><li>Selecione <strong>Show</strong> para revisar detalhes, identidades, caixas vinculadas e atividade.</li><li>Se tiver permissão, selecione <strong>Edit Customer</strong> para alterar o perfil.</li></ol><p>Em uma conversa, consulte os dados disponíveis e User Notes na barra lateral direita. A associação de identidades depende dos identificadores fornecidos por cada canal.</p>"
                },
                ar: {
                  title: "ملفات تعريف العملاء والجدول الزمني للتفاعل",
                  content: "<p>يعرض الملف معلومات الاتصال وهويات القنوات التي ربطها Deskbolic بالشخص، إضافة إلى صناديق الوارد المرتبطة وعدد المحادثات وآخر نشاط.</p><h3>العثور على ملف</h3><ol><li>افتح <strong>Customers</strong> من قائمة لوحة التحكم.</li><li>ابحث بالاسم أو بيانات الاتصال. صفِّ النتائج حسب القناة أو رتّبها حسب الأحدث أو الأقدم أو الاسم.</li><li>اختر <strong>Show</strong> لمراجعة التفاصيل والهويات وصناديق الوارد والنشاط.</li><li>إذا كان لديك الإذن، اختر <strong>Edit Customer</strong> لتعديل الملف.</li></ol><p>داخل المحادثة، راجع معلومات العميل المتاحة وUser Notes في اللوحة الجانبية اليمنى. يعتمد ربط هوية القناة على المعرّفات التي توفرها القناة.</p>"
                },
                ko: {
                  title: "고객 프로필 및 상담 타임라인",
                  content: "<p>고객 레코드에는 Deskbolic이 연결한 연락처 정보와 채널 ID가 표시됩니다. 프로필에서 연결된 받은 편지함, 대화 수, 최근 활동을 확인할 수 있습니다.</p><h3>고객 찾기</h3><ol><li>대시보드 설정 메뉴에서 <strong>Customers</strong>를 엽니다.</li><li>이름 또는 연락처로 검색합니다. 채널 필터와 최신순/오래된순/이름순 정렬을 사용할 수 있습니다.</li><li><strong>Show</strong>를 선택해 고객 정보, 연결된 ID와 받은 편지함, 대화 수, 최근 활동을 확인합니다.</li><li>권한이 있다면 <strong>Edit Customer</strong>를 선택해 프로필 정보를 수정합니다.</li></ol><p>대화 화면에서는 고객 정보 사이드바에서 이용 가능한 프로필 정보와 User Notes를 확인하세요. 채널 ID 연결은 각 채널에서 제공하는 식별자에 따라 달라집니다.</p>"
                }
              }
            },
            {
              key: :custom_fields,
              position: 2,
              translations: {
                en: { title: "Create and Configure Custom Fields", content: "<p>Custom fields store structured information on either a customer or a conversation. Choose the record type carefully: it and the field's input type and key cannot be changed after creation.</p><h3>Create a field</h3><ol><li>Open <strong>Settings → Custom Fields</strong> and select <strong>Create New Field</strong>.</li><li>Enter a unique lowercase key using letters, numbers, and underscores. Choose <strong>Customer</strong> or <strong>Conversation</strong>, then choose an input type such as text, email, number, textarea, select, multi-select, checkbox, file, date, or URL.</li><li>Optionally map the field to one of the offered core attributes. The record type may be set by the mapping.</li><li>Set a default value if appropriate. Add validation rules supported by the selected input type, such as length/pattern for text or minimum/maximum for numbers.</li><li>Set the required, searchable, read-only, or hidden options as needed. Hidden fields are not rendered in standard interfaces; read-only fields are displayed but agents cannot edit them.</li><li>Add localized labels, placeholders, descriptions, and select-option labels for the languages you support, then save.</li></ol><h3>Review and maintain fields</h3><p>Use the All, Customer, and Conversation filters and search on the Custom Fields page to find a definition. A field in use cannot always be deleted. Add fields deliberately: customer fields describe the person, while conversation fields describe a specific support case.</p>" },
                de: { title: "Benutzerdefinierte Felder erstellen und konfigurieren", content: "<p>Benutzerdefinierte Felder speichern strukturierte Daten für einen Kunden oder eine Konversation. Datensatztyp, Eingabetyp und Schlüssel lassen sich nach dem Erstellen nicht ändern.</p><h3>Feld erstellen</h3><ol><li>Öffnen Sie <strong>Einstellungen → Custom Fields</strong> und wählen Sie <strong>Create New Field</strong>.</li><li>Geben Sie einen eindeutigen Schlüssel aus Kleinbuchstaben, Zahlen und Unterstrichen ein. Wählen Sie <strong>Customer</strong> oder <strong>Conversation</strong> sowie einen Eingabetyp, etwa Text, E-Mail, Zahl, Textbereich, Auswahl, Mehrfachauswahl, Kontrollkästchen, Datei, Datum oder URL.</li><li>Ordnen Sie das Feld bei Bedarf einem angebotenen Standardattribut zu. Dadurch kann der Datensatztyp festgelegt werden.</li><li>Legen Sie optional einen Standardwert und passende Validierungen fest.</li><li>Konfigurieren Sie erforderlich, durchsuchbar, schreibgeschützt oder ausgeblendet. Ausgeblendete Felder erscheinen nicht in Standardansichten; schreibgeschützte Felder können Agenten nicht bearbeiten.</li><li>Ergänzen Sie übersetzte Bezeichnungen, Platzhalter, Beschreibungen und Auswahloptionen und speichern Sie.</li></ol><h3>Felder finden</h3><p>Nutzen Sie die Filter Alle, Kunde und Konversation sowie die Suche. Ein verwendetes Feld kann möglicherweise nicht gelöscht werden. Kundenfelder beschreiben die Person, Konversationsfelder einen einzelnen Supportfall.</p>" },
                es: { title: "Crear y configurar campos personalizados", content: "<p>Los campos personalizados guardan datos estructurados de un cliente o una conversación. El tipo de registro, el tipo de entrada y la clave no se pueden cambiar después de crear el campo.</p><h3>Crear un campo</h3><ol><li>Abra <strong>Configuración → Custom Fields</strong> y seleccione <strong>Create New Field</strong>.</li><li>Escriba una clave única con minúsculas, números y guiones bajos. Elija <strong>Customer</strong> o <strong>Conversation</strong> y un tipo: texto, correo, número, área de texto, selección, selección múltiple, casilla, archivo, fecha o URL.</li><li>Si lo necesita, vincule el campo a uno de los atributos principales ofrecidos; la asignación puede determinar el tipo de registro.</li><li>Configure un valor predeterminado y las validaciones compatibles con el tipo de entrada.</li><li>Marque el campo como obligatorio, buscable, de solo lectura u oculto. Los campos ocultos no aparecen en las interfaces habituales; los de solo lectura se muestran pero los agentes no pueden editarlos.</li><li>Añada etiquetas, marcadores, descripciones y opciones traducidas para los idiomas que use y guarde.</li></ol><h3>Buscar y mantener campos</h3><p>Use los filtros Todos, Cliente y Conversación y la búsqueda. Puede que no sea posible eliminar un campo que esté en uso. Los campos de cliente describen a la persona; los de conversación, un caso de soporte concreto.</p>" },
                fr: { title: "Créer et configurer des champs personnalisés", content: "<p>Les champs personnalisés enregistrent des données structurées sur un client ou une conversation. Le type d'enregistrement, le type de saisie et la clé ne peuvent plus être modifiés après création.</p><h3>Créer un champ</h3><ol><li>Ouvrez <strong>Paramètres → Custom Fields</strong> et choisissez <strong>Create New Field</strong>.</li><li>Saisissez une clé unique en minuscules, chiffres et traits de soulignement. Choisissez <strong>Customer</strong> ou <strong>Conversation</strong>, puis un type : texte, e-mail, nombre, zone de texte, sélection, sélection multiple, case, fichier, date ou URL.</li><li>Associez éventuellement le champ à un attribut principal proposé ; cette association peut définir le type d'enregistrement.</li><li>Ajoutez si besoin une valeur par défaut et les validations prises en charge par le type.</li><li>Configurez obligatoire, recherchable, lecture seule ou masqué. Les champs masqués ne s'affichent pas dans les interfaces standard ; les champs en lecture seule sont visibles mais non modifiables par les agents.</li><li>Ajoutez les libellés, espaces réservés, descriptions et options traduits pour les langues utilisées, puis enregistrez.</li></ol><h3>Retrouver et gérer les champs</h3><p>Utilisez les filtres Tous, Client et Conversation et la recherche. Un champ utilisé ne peut pas toujours être supprimé. Les champs client décrivent la personne ; les champs de conversation décrivent un dossier précis.</p>" },
                "pt-BR": { title: "Criar e configurar campos personalizados", content: "<p>Campos personalizados armazenam dados estruturados de um cliente ou de uma conversa. O tipo do registro, o tipo de entrada e a chave não podem ser alterados depois da criação.</p><h3>Criar um campo</h3><ol><li>Abra <strong>Configurações → Custom Fields</strong> e selecione <strong>Create New Field</strong>.</li><li>Informe uma chave exclusiva com letras minúsculas, números e sublinhados. Escolha <strong>Customer</strong> ou <strong>Conversation</strong> e um tipo: texto, e-mail, número, área de texto, seleção, seleção múltipla, caixa de seleção, arquivo, data ou URL.</li><li>Se necessário, mapeie o campo para um atributo principal disponível; o mapeamento pode definir o tipo do registro.</li><li>Configure um valor padrão e validações compatíveis com o tipo de entrada.</li><li>Marque como obrigatório, pesquisável, somente leitura ou oculto. Campos ocultos não aparecem nas interfaces padrão; agentes veem campos somente leitura, mas não podem editá-los.</li><li>Adicione rótulos, dicas, descrições e opções traduzidas para os idiomas usados e salve.</li></ol><h3>Localizar e manter campos</h3><p>Use os filtros Todos, Cliente e Conversa e a busca. Um campo em uso pode não poder ser excluído. Campos de cliente descrevem a pessoa; campos de conversa descrevem um atendimento específico.</p>" },
                ar: { title: "إنشاء الحقول المخصصة وإعدادها", content: "<p>تخزن الحقول المخصصة بيانات منظمة للعميل أو للمحادثة. لا يمكن تغيير نوع السجل ونوع الإدخال والمفتاح بعد إنشاء الحقل.</p><h3>إنشاء حقل</h3><ol><li>افتح <strong>Settings → Custom Fields</strong> واختر <strong>Create New Field</strong>.</li><li>أدخل مفتاحًا فريدًا بأحرف صغيرة وأرقام وشرطات سفلية. اختر <strong>Customer</strong> أو <strong>Conversation</strong> ونوع الإدخال: نص، بريد إلكتروني، رقم، مساحة نص، اختيار، اختيار متعدد، مربع اختيار، ملف، تاريخ أو URL.</li><li>يمكنك ربط الحقل بإحدى السمات الأساسية المتاحة؛ وقد يحدد الربط نوع السجل.</li><li>أضف قيمة افتراضية وقواعد تحقق مناسبة لنوع الإدخال عند الحاجة.</li><li>حدد مطلوب أو قابل للبحث أو للقراءة فقط أو مخفي. لا تظهر الحقول المخفية في الواجهات القياسية؛ وتظهر حقول القراءة فقط دون إمكانية تعديلها بواسطة الوكلاء.</li><li>أضف التسميات والعناصر النائبة والأوصاف وخيارات الاختيار المترجمة للغات التي تستخدمها ثم احفظ.</li></ol><h3>البحث والإدارة</h3><p>استخدم مرشحات الكل والعميل والمحادثة والبحث. قد يتعذر حذف حقل مستخدم. تصف حقول العميل الشخص، بينما تصف حقول المحادثة حالة دعم محددة.</p>" },
                ko: { title: "사용자 지정 필드 만들기 및 설정", content: "<p>사용자 지정 필드는 고객 또는 대화 레코드에 구조화된 정보를 저장합니다. 레코드 유형, 입력 유형, 키는 생성 후 변경할 수 없습니다.</p><h3>필드 만들기</h3><ol><li><strong>설정 → Custom Fields</strong>를 열고 <strong>Create New Field</strong>를 선택합니다.</li><li>소문자, 숫자, 밑줄로 고유 키를 입력합니다. <strong>Customer</strong> 또는 <strong>Conversation</strong>와 텍스트, 이메일, 숫자, 여러 줄 텍스트, 선택, 다중 선택, 체크박스, 파일, 날짜, URL 등의 입력 유형을 지정합니다.</li><li>필요하면 제공된 기본 속성에 매핑합니다. 매핑에 따라 레코드 유형이 결정될 수 있습니다.</li><li>기본값과 입력 유형에 맞는 유효성 검사를 설정합니다.</li><li>필수, 검색 가능, 읽기 전용, 숨김 여부를 선택합니다. 숨김 필드는 표준 화면에 표시되지 않고, 읽기 전용 필드는 상담원이 볼 수 있지만 수정할 수 없습니다.</li><li>지원 언어별 라벨, 안내문, 설명, 선택 항목 번역을 추가하고 저장합니다.</li></ol><h3>필드 찾기 및 관리</h3><p>전체, 고객, 대화 필터와 검색을 사용합니다. 사용 중인 필드는 삭제가 제한될 수 있습니다. 고객 필드는 사람을 설명하고 대화 필드는 특정 문의 건을 설명합니다.</p>" }
              }
            }
          ]
        end
      end
    end
  end
end
