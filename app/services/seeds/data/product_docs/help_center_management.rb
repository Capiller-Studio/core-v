# frozen_string_literal: true

module Seeds
  module Data
    module ProductDocs
      module HelpCenterManagement
        def self.category
          {
            key: :help_center_management,
            icon_key: "book",
            position: 7,
            translations: {
              en: {
                name: "Knowledge Base & Help Center",
                description: "Create a customer-facing help portal, organize articles, and manage portal branding and languages."
              },
              de: {
                name: "Wissensdatenbank & Help Center",
                description: "Erstellen Sie ein Help-Center-Portal, organisieren Sie Artikel und verwalten Sie Branding und Sprachen."
              },
              es: {
                name: "Base de Conocimientos y Centro de Ayuda",
                description: "Cree un portal de ayuda, organice artículos y gestione la marca y los idiomas del portal."
              },
              fr: {
                name: "Base de Connaissances et Centre d'Aide",
                description: "Créez un centre d'aide, organisez les articles et gérez son apparence et ses langues."
              },
              "pt-BR": {
                name: "Base de Conhecimento e Central de Ajuda",
                description: "Crie uma central de ajuda, organize artigos e gerencie a aparência e os idiomas do portal."
              },
              ar: {
                name: "قاعدة المعرفة ومركز المساعدة",
                description: "أنشئ مركز مساعدة للعملاء، ونظّم المقالات، وأدر مظهر البوابة ولغاتها."
              },
              ko: {
                name: "지식 기반 및 헬프 센터 관리",
                description: "고객용 헬프 센터를 만들고 문서를 정리하며 포털의 모양과 언어를 관리합니다."
              }
            }
          }
        end

        def self.articles(api_portal_domain: "api-rely.capiller.com")
          api_url = "https://#{api_portal_domain}"

          [
            {
              key: :help_center_setup,
              position: 1,
              translations: {
                en: {
                  title: "Set Up and Customize Your Help Center",
                  content: <<~HTML
                    <p>Your Help Center is a public portal where customers can find your published support articles. You can manage portals, their appearance, languages, categories, and articles from the Help Center area in the dashboard.</p>
                    <ol>
                      <li>Open <strong>Help Center</strong> in the settings sidebar and choose <strong>Create Help Center</strong>, or open <strong>All Help Centers</strong> to manage an existing portal.</li>
                      <li>When creating a portal, enter its name and choose an available Capiller Rely subdomain or a custom domain if your account plan supports custom domains.</li>
                      <li>Open the portal's edit page to set its supported locales, branding, logo, hero presentation, and other appearance options.</li>
                      <li>Use <strong>Articles</strong> and <strong>Categories</strong> in the Help Center sidebar to add and organize customer-facing content. Only publish content after reviewing it in the intended language.</li>
                    </ol>
                    <p>Custom-domain setup depends on your plan and the domain options shown in the portal form. The portal form provides the applicable setup details.</p>
                  HTML
                },
                de: {
                  title: "Wissensportale erstellen & anpassen",
                  content: "<p>Das Help Center ist ein öffentliches Portal mit veröffentlichten Supportartikeln. Portale, Sprachen, Erscheinungsbild, Kategorien und Artikel verwalten Sie im Dashboard.</p><ol><li>Öffnen Sie <strong>Help Center</strong> in der Einstellungsseitenleiste. Wählen Sie <strong>Create Help Center</strong> oder <strong>All Help Centers</strong>.</li><li>Geben Sie beim Erstellen einen Namen ein und wählen Sie eine verfügbare Capiller Rely-Subdomain oder – sofern Ihr Tarif dies unterstützt – eine eigene Domain.</li><li>Öffnen Sie die Bearbeitungsseite und konfigurieren Sie unterstützte Sprachen, Branding, Logo und Darstellung.</li><li>Erstellen und ordnen Sie kundenorientierte Inhalte unter <strong>Articles</strong> und <strong>Categories</strong>. Prüfen Sie jede Sprache vor der Veröffentlichung.</li></ol><p>Die verfügbaren Domainoptionen und Einrichtungsschritte hängen vom Tarif und den Angaben im Formular ab.</p>"
                },
                es: {
                  title: "Creación y Personalización de Portales de Ayuda",
                  content: "<p>El Help Center es un portal público con artículos de soporte publicados. Administre portales, idiomas, apariencia, categorías y artículos desde el panel.</p><ol><li>Abra <strong>Help Center</strong> en la barra lateral de configuración. Elija <strong>Create Help Center</strong> o <strong>All Help Centers</strong>.</li><li>Al crear un portal, escriba el nombre y elija un subdominio disponible de Capiller Rely o un dominio propio si su plan lo permite.</li><li>Abra la página de edición para configurar idiomas, marca, logotipo y presentación.</li><li>Cree y organice el contenido para clientes en <strong>Articles</strong> y <strong>Categories</strong>. Revise cada idioma antes de publicar.</li></ol><p>Las opciones de dominio y los pasos aplicables dependen del plan y de lo que muestre el formulario.</p>"
                },
                fr: {
                  title: "Création et Personnalisation des Portails d'Aide",
                  content: "<p>Le Help Center est un portail public où les clients consultent les articles publiés. Gérez les portails, langues, apparence, catégories et articles depuis le tableau de bord.</p><ol><li>Ouvrez <strong>Help Center</strong> dans la barre latérale des paramètres. Choisissez <strong>Create Help Center</strong> ou <strong>All Help Centers</strong>.</li><li>Lors de la création, saisissez un nom et choisissez un sous-domaine Capiller Rely disponible ou un domaine personnalisé si votre forfait l'autorise.</li><li>Ouvrez la page de modification pour définir les langues, l'identité visuelle, le logo et la présentation.</li><li>Créez et organisez les contenus clients dans <strong>Articles</strong> et <strong>Categories</strong>. Relisez chaque langue avant publication.</li></ol><p>Les domaines proposés et les étapes de configuration dépendent de votre forfait et du formulaire.</p>"
                },
                "pt-BR": {
                  title: "Criando e Personalizando Portais de Ajuda",
                  content: "<p>O Help Center é um portal público com artigos de suporte publicados. Gerencie portais, idiomas, aparência, categorias e artigos pelo painel.</p><ol><li>Abra <strong>Help Center</strong> na barra lateral de configurações e escolha <strong>Create Help Center</strong> ou <strong>All Help Centers</strong>.</li><li>Ao criar, informe um nome e escolha um subdomínio Capiller Rely disponível ou um domínio próprio, se o plano permitir.</li><li>Abra a edição do portal para configurar idiomas, marca, logotipo e apresentação.</li><li>Crie e organize conteúdo para clientes em <strong>Articles</strong> e <strong>Categories</strong>. Revise cada idioma antes de publicar.</li></ol><p>As opções de domínio e os passos aplicáveis dependem do plano e do formulário exibido.</p>"
                },
                ar: {
                  title: "إنشاء وتخصيص بوابات مركز المساعدة",
                  content: "<p>مركز المساعدة بوابة عامة تعرض مقالات الدعم المنشورة. يمكنك إدارة البوابات واللغات والمظهر والفئات والمقالات من لوحة التحكم.</p><ol><li>افتح <strong>Help Center</strong> من الشريط الجانبي للإعدادات واختر <strong>Create Help Center</strong> أو <strong>All Help Centers</strong>.</li><li>عند الإنشاء، أدخل اسمًا واختر نطاق Capiller Rely فرعيًا متاحًا أو نطاقًا مخصصًا إذا كانت خطتك تسمح بذلك.</li><li>افتح صفحة التعديل لضبط اللغات المدعومة والعلامة التجارية والشعار وطريقة العرض.</li><li>أنشئ محتوى العملاء ونظمه في <strong>Articles</strong> و<strong>Categories</strong>. راجع كل لغة قبل النشر.</li></ol><p>تعتمد خيارات النطاق وخطوات إعداده على خطتك وما يعرضه النموذج.</p>"
                },
                ko: {
                  title: "지식 기반 헬프 센터 포털 생성 및 맞춤 설정",
                  content: "<p>Help Center는 게시된 지원 문서를 고객에게 제공하는 공개 포털입니다. 대시보드에서 포털, 언어, 디자인, 카테고리, 문서를 관리할 수 있습니다.</p><ol><li>설정 사이드바에서 <strong>Help Center</strong>를 열고 <strong>Create Help Center</strong> 또는 <strong>All Help Centers</strong>를 선택합니다.</li><li>새 포털의 이름을 입력하고 사용 가능한 Capiller Rely 하위 도메인을 선택합니다. 요금제에서 허용하면 사용자 지정 도메인도 선택할 수 있습니다.</li><li>편집 화면에서 지원 언어, 브랜드, 로고, 화면 표시 방식을 설정합니다.</li><li><strong>Articles</strong>와 <strong>Categories</strong>에서 고객용 콘텐츠를 만들고 정리합니다. 게시 전에 각 언어를 검토하세요.</li></ol><p>도메인 옵션과 설정 단계는 요금제와 포털 양식에 표시되는 내용에 따라 달라집니다.</p>"
                }
              }
            },
            {
              key: :create_and_publish_help_articles,
              position: 2,
              translations: {
                en: {
                  title: "Create, Review, and Publish a Help Article",
                  content: <<~HTML
                    <p>Articles are the main content customers read in your Help Center. Save drafts while writing, then publish when the content is ready for customers.</p>
                    <ol>
                      <li>Open <strong>Help Center &rarr; Articles</strong> in the dashboard and select <strong>New Article</strong>.</li>
                      <li>Choose the portal and primary category, select the article type, and enter the title and content for the selected language.</li>
                      <li>Review the article's visibility and other publishing options. Add any available translations using the locale controls in the editor, and review each translation yourself.</li>
                      <li>Choose <strong>Save</strong> to keep a draft, or <strong>Publish</strong> to make the article available according to its visibility settings.</li>
                      <li>Open the public portal and check the article's language, formatting, links, and category placement.</li>
                    </ol>
                    <p>Publishing a translation requires that translation's content to be prepared in the editor. Do not assume the system has translated the article automatically.</p>
                  HTML
                },
                de: { title: "Hilfeartikel erstellen und veröffentlichen", content: "<p>Artikel sind die Inhalte, die Kunden im Help Center lesen. Speichern Sie beim Schreiben einen Entwurf und veröffentlichen Sie erst nach der Prüfung.</p><ol><li>Öffnen Sie <strong>Help Center → Articles</strong> und wählen Sie <strong>New Article</strong>.</li><li>Wählen Sie Portal und Hauptkategorie, legen Sie den Artikeltyp fest und schreiben Sie Titel und Inhalt in der ausgewählten Sprache.</li><li>Prüfen Sie Sichtbarkeit und Veröffentlichungsoptionen. Ergänzen Sie Sprachen im Editor und prüfen Sie jede Übersetzung selbst.</li><li>Wählen Sie <strong>Save</strong> für einen Entwurf oder <strong>Publish</strong>, um den Artikel entsprechend seiner Sichtbarkeit bereitzustellen.</li><li>Prüfen Sie Sprache, Formatierung, Links und Kategorie im öffentlichen Portal.</li></ol><p>Übersetzungen werden nicht automatisch erstellt.</p>" },
                es: { title: "Crear y publicar artículos de ayuda", content: "<p>Los artículos son el contenido que leen los clientes en el Help Center. Guarde un borrador mientras escribe y publique después de revisarlo.</p><ol><li>Abra <strong>Help Center → Articles</strong> y seleccione <strong>New Article</strong>.</li><li>Elija el portal y la categoría principal, seleccione el tipo de artículo y escriba el título y el contenido en el idioma elegido.</li><li>Revise la visibilidad y las opciones de publicación. Añada los idiomas desde el editor y revise cada traducción.</li><li>Seleccione <strong>Save</strong> para guardar un borrador o <strong>Publish</strong> para mostrar el artículo según su visibilidad.</li><li>Compruebe en el portal público el idioma, el formato, los enlaces y la categoría.</li></ol><p>Las traducciones no se generan automáticamente.</p>" },
                fr: { title: "Créer et publier un article d'aide", content: "<p>Les articles constituent le contenu du Help Center. Enregistrez un brouillon pendant la rédaction et publiez après vérification.</p><ol><li>Ouvrez <strong>Help Center → Articles</strong> et choisissez <strong>New Article</strong>.</li><li>Choisissez le portail et la catégorie principale, le type d'article, puis saisissez le titre et le contenu dans la langue sélectionnée.</li><li>Vérifiez la visibilité et les options de publication. Ajoutez les langues dans l'éditeur et relisez chaque traduction.</li><li>Choisissez <strong>Save</strong> pour garder un brouillon ou <strong>Publish</strong> pour rendre l'article accessible selon sa visibilité.</li><li>Vérifiez la langue, la mise en forme, les liens et la catégorie sur le portail public.</li></ol><p>Les traductions ne sont pas générées automatiquement.</p>" },
                "pt-BR": { title: "Criar e publicar um artigo de ajuda", content: "<p>Os artigos são o conteúdo que os clientes leem no Help Center. Salve um rascunho durante a escrita e publique depois da revisão.</p><ol><li>Abra <strong>Help Center → Articles</strong> e selecione <strong>New Article</strong>.</li><li>Escolha o portal e a categoria principal, selecione o tipo e escreva título e conteúdo no idioma escolhido.</li><li>Revise a visibilidade e as opções de publicação. Adicione idiomas no editor e revise cada tradução.</li><li>Selecione <strong>Save</strong> para manter como rascunho ou <strong>Publish</strong> para disponibilizar o artigo conforme a visibilidade.</li><li>No portal público, confira idioma, formatação, links e categoria.</li></ol><p>As traduções não são criadas automaticamente.</p>" },
                ar: { title: "إنشاء مقالة مساعدة ومراجعتها ونشرها", content: "<p>المقالات هي المحتوى الذي يقرأه العملاء في مركز المساعدة. احفظ مسودة أثناء الكتابة وانشر بعد المراجعة.</p><ol><li>افتح <strong>Help Center → Articles</strong> واختر <strong>New Article</strong>.</li><li>حدد البوابة والفئة الرئيسية ونوع المقالة، ثم أدخل العنوان والمحتوى باللغة المختارة.</li><li>راجع إعدادات الظهور والنشر. أضف اللغات من المحرر وراجع كل ترجمة يدويًا.</li><li>اختر <strong>Save</strong> لحفظ مسودة أو <strong>Publish</strong> لإتاحة المقالة وفق إعداد الظهور.</li><li>تحقق من اللغة والتنسيق والروابط والفئة في البوابة العامة.</li></ol><p>لا تُنشأ الترجمات تلقائيًا.</p>" },
                ko: { title: "도움말 문서 작성 및 게시", content: "<p>문서는 고객이 Help Center에서 읽는 콘텐츠입니다. 작성 중에는 초안으로 저장하고 검토가 끝난 후 게시하세요.</p><ol><li><strong>Help Center → Articles</strong>를 열고 <strong>New Article</strong>을 선택합니다.</li><li>포털과 기본 카테고리, 문서 유형을 고르고 선택한 언어로 제목과 내용을 작성합니다.</li><li>공개 범위와 게시 옵션을 확인합니다. 편집기에서 필요한 언어를 추가하고 각 번역을 직접 검토합니다.</li><li><strong>Save</strong>로 초안을 저장하거나 <strong>Publish</strong>를 선택해 공개 범위에 따라 문서를 게시합니다.</li><li>공개 포털에서 언어, 서식, 링크, 카테고리를 확인합니다.</li></ol><p>번역은 자동으로 생성되지 않습니다.</p>" }
              }
            },
            {
              key: :organize_help_center_categories,
              position: 3,
              translations: {
                en: {
                  title: "Organize Help Articles with Categories",
                  content: <<~HTML
                    <p>Categories group related articles so customers can browse the Help Center. An article has a primary category and can also be associated with additional categories.</p>
                    <ol>
                      <li>Open <strong>Help Center &rarr; Categories</strong> and create a category.</li>
                      <li>Enter the category name and description for the portal language, and choose the portal and display options shown in the form.</li>
                      <li>When creating or editing an article, choose its primary category. Associate additional categories when the article belongs in more than one place.</li>
                      <li>Review the published portal navigation and category pages to confirm customers can find the articles.</li>
                    </ol>
                    <p>Use clear, customer-facing names and avoid creating overlapping categories that make content difficult to browse.</p>
                  HTML
                },
                de: { title: "Hilfeartikel mit Kategorien organisieren", content: "<p>Kategorien gruppieren zusammengehörige Artikel. Ein Artikel hat eine Hauptkategorie und kann zusätzlich weiteren Kategorien zugeordnet werden.</p><ol><li>Öffnen Sie <strong>Help Center → Categories</strong> und erstellen Sie eine Kategorie.</li><li>Geben Sie Name und Beschreibung in der Portalsprache ein und wählen Sie Portal und Anzeigeoptionen im Formular.</li><li>Wählen Sie beim Erstellen oder Bearbeiten eines Artikels die Hauptkategorie und bei Bedarf zusätzliche Kategorien.</li><li>Prüfen Sie Navigation und Kategorieseiten im veröffentlichten Portal.</li></ol><p>Verwenden Sie klare Kundennamen und vermeiden Sie überlappende Kategorien.</p>" },
                es: { title: "Organizar artículos con categorías", content: "<p>Las categorías agrupan artículos relacionados para que los clientes puedan explorarlos. Cada artículo tiene una categoría principal y puede asociarse a otras.</p><ol><li>Abra <strong>Help Center → Categories</strong> y cree una categoría.</li><li>Escriba el nombre y la descripción en el idioma del portal y configure las opciones que aparecen en el formulario.</li><li>Al crear o editar un artículo, elija su categoría principal y añada otras si corresponde.</li><li>Revise la navegación y las páginas de categorías en el portal publicado.</li></ol><p>Use nombres claros para clientes y evite categorías que se solapen.</p>" },
                fr: { title: "Organiser les articles avec des catégories", content: "<p>Les catégories regroupent les articles associés. Un article possède une catégorie principale et peut en avoir d'autres.</p><ol><li>Ouvrez <strong>Help Center → Categories</strong> et créez une catégorie.</li><li>Saisissez son nom et sa description dans la langue du portail et choisissez les options proposées.</li><li>Lors de la création ou modification d'un article, choisissez sa catégorie principale et ajoutez-en d'autres si besoin.</li><li>Vérifiez la navigation et les pages de catégories sur le portail publié.</li></ol><p>Choisissez des noms compréhensibles par les clients et évitez les catégories redondantes.</p>" },
                "pt-BR": { title: "Organizar artigos com categorias", content: "<p>As categorias agrupam artigos relacionados para facilitar a navegação. Cada artigo tem uma categoria principal e pode ser associado a outras.</p><ol><li>Abra <strong>Help Center → Categories</strong> e crie uma categoria.</li><li>Informe nome e descrição no idioma do portal e escolha as opções exibidas no formulário.</li><li>Ao criar ou editar um artigo, selecione a categoria principal e associe outras quando necessário.</li><li>Confira a navegação e as páginas de categoria no portal publicado.</li></ol><p>Use nomes claros para os clientes e evite categorias redundantes.</p>" },
                ar: { title: "تنظيم مقالات المساعدة باستخدام الفئات", content: "<p>تجمع الفئات المقالات المرتبطة لتسهيل التصفح. لكل مقالة فئة رئيسية ويمكن ربطها بفئات إضافية.</p><ol><li>افتح <strong>Help Center → Categories</strong> وأنشئ فئة.</li><li>أدخل الاسم والوصف بلغة البوابة وحدد خيارات العرض التي يوفرها النموذج.</li><li>عند إنشاء مقالة أو تعديلها، اختر الفئة الرئيسية وأضف فئات أخرى عند الحاجة.</li><li>راجع التنقل وصفحات الفئات في البوابة المنشورة.</li></ol><p>استخدم أسماء واضحة للعملاء وتجنب الفئات المتداخلة.</p>" },
                ko: { title: "카테고리로 도움말 문서 정리", content: "<p>카테고리는 관련 문서를 그룹화해 고객이 찾기 쉽게 합니다. 문서에는 기본 카테고리를 지정하고 추가 카테고리에도 연결할 수 있습니다.</p><ol><li><strong>Help Center → Categories</strong>를 열고 카테고리를 만듭니다.</li><li>포털 언어로 이름과 설명을 입력하고 양식에서 제공하는 표시 옵션을 설정합니다.</li><li>문서를 만들거나 수정할 때 기본 카테고리를 선택하고 필요하면 추가 카테고리를 연결합니다.</li><li>게시된 포털에서 탐색 메뉴와 카테고리 페이지를 확인합니다.</li></ol><p>고객이 이해하기 쉬운 이름을 사용하고 서로 겹치는 카테고리는 피하세요.</p>" }
              }
            },
            {
              key: :api_reference_portal_link,
              position: 4,
              translations: {
                en: {
                  title: "Developer Platform & API Reference Portal",
                  content: <<~HTML
                    <p>For developers building integrations with Capiller Rely, open the API documentation portal. Use its current reference to confirm available endpoints, authentication requirements, and request formats.</p>
                    <div style="padding: 20px; border-radius: 12px; background: #EEF2FF; border: 1px solid #C7D2FE; margin: 20px 0;">
                      <h4 style="margin: 0 0 8px 0; color: #3730A3;">Explore the Capiller Rely API Reference</h4>
                      <p style="margin: 0 0 14px 0; color: #4338CA;">Review the available API documentation and integration guidance.</p>
                      <a href="#{api_url}" target="_blank" rel="noopener noreferrer" style="display: inline-block; background: #3b82f6; color: #ffffff; padding: 10px 18px; border-radius: 8px; text-decoration: none; font-weight: 600;">Open API Documentation &rarr;</a>
                    </div>
                  HTML
                },
                de: {
                  title: "Entwicklerplattform & API-Referenzportal",
                  content: <<~HTML
                    <p>Möchten Sie benutzerdefinierte Integrationen oder Bots erstellen? Nutzen Sie das offizielle Capiller Rely API-Referenzportal.</p>
                    <p><a href="#{api_url}" target="_blank" rel="noopener noreferrer"><strong>API-Dokumentation öffnen &rarr;</strong></a></p>
                  HTML
                },
                es: {
                  title: "Plataforma de Desarrolladores y Portal de API",
                  content: <<~HTML
                    <p>¿Desea crear integraciones personalizadas o bots? Visite el portal oficial de referencia de la API de Capiller Rely.</p>
                    <p><a href="#{api_url}" target="_blank" rel="noopener noreferrer"><strong>Abrir Documentación de la API &rarr;</strong></a></p>
                  HTML
                },
                fr: {
                  title: "Plateforme Développeurs et Référence API",
                  content: <<~HTML
                    <p>Vous souhaitez créer des intégrations ou des bots? Consultez le portail de référence de l'API Capiller Rely.</p>
                    <p><a href="#{api_url}" target="_blank" rel="noopener noreferrer"><strong>Ouvrir la Documentation API &rarr;</strong></a></p>
                  HTML
                },
                "pt-BR": {
                  title: "Plataforma de Desenvolvedores e Referência da API",
                  content: <<~HTML
                    <p>Deseja criar integrações personalizadas ou bots? Acesse o portal oficial de referência da API Capiller Rely.</p>
                    <p><a href="#{api_url}" target="_blank" rel="noopener noreferrer"><strong>Abrir Documentação da API &rarr;</strong></a></p>
                  HTML
                },
                ar: {
                  title: "منصة المطورين ومرجع واجهة برمجة التطبيقات (API)",
                  content: <<~HTML
                    <p>هل ترغب في بناء عمليات تكامل مخصصة أو روبوتات محادثة؟ قم بزيارة بوابة مرجع واجهة برمجة تطبيقات Capiller Rely الرسمية.</p>
                    <p><a href="#{api_url}" target="_blank" rel="noopener noreferrer"><strong>فتح وثائق واجهة برمجة التطبيقات &rarr;</strong></a></p>
                  HTML
                },
                ko: {
                  title: "개발자 플랫폼 및 API 레퍼런스 포털 바로가기",
                  content: <<~HTML
                    <p>자체 서비스 연동, 챗봇 또는 백엔드 자동화를 구축하려면 Capiller Rely 공식 <strong>REST API 레퍼런스 포털</strong>을 확인하세요.</p>
                    <p><a href="#{api_url}" target="_blank" rel="noopener noreferrer"><strong>API 공식 설명서 열기 &rarr;</strong></a></p>
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
