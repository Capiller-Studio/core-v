# frozen_string_literal: true

module Seeds
  class ApiDocumentationSeeder
    def self.seed(domain:)
      puts "Seeding API Documentation on domain: #{domain}..."
      
      account = Account.first
      unless account
        puts "Skipping API documentation seed: No account found in DB."
        return
      end
      
      account.with_shard do
        domain_record = Domain.find_or_create_by!(value: domain, account: account) do |d|
          d.domain_type = :custom
        end
        domain_record.update!(
          status: :active, 
          dns_status: :dns_verified, 
          ssl_status: :ssl_active, 
          dns_verified_at: Time.current, 
          domain_type: :custom
        )
        
        portal = HelpCenter::Portal.find_or_initialize_by(domain_id: domain_record.id)
        portal.account = account
        portal.name = "Deskbolic API Reference"
        portal.default_locale = "en"
        portal.locales = ["en", "fr", "es"]
        portal.status = :active
        portal.footer_text = "&copy; #{Time.current.year} Deskbolic. All rights reserved."
        portal.ui_configurations = (portal.ui_configurations || {}).merge("primary_color" => "#4f46e5")
        portal.save!

        # Categories
        cat_intro = portal.categories.joins(:translations).find_by(help_center_category_translations: { locale: 'en', name: 'Getting Started' }) || portal.categories.new(account: account, portal: portal)
        cat_intro.update!(status: :active, visibility: :everyone, featured: true, position: 1)

        cat_inbox = portal.categories.joins(:translations).find_by(help_center_category_translations: { locale: 'en', name: 'Inboxes' }) || portal.categories.new(account: account, portal: portal)
        cat_inbox.update!(api_reference: true, status: :active, visibility: :everyone, featured: true, position: 2)

        cat_cust = portal.categories.joins(:translations).find_by(help_center_category_translations: { locale: 'en', name: 'Customers' }) || portal.categories.new(account: account, portal: portal)
        cat_cust.update!(api_reference: true, status: :active, visibility: :everyone, featured: true, position: 3)

        cat_conv = portal.categories.joins(:translations).find_by(help_center_category_translations: { locale: 'en', name: 'Conversations' }) || portal.categories.new(account: account, portal: portal)
        cat_conv.update!(api_reference: true, status: :active, visibility: :everyone, featured: true, position: 4)

        cat_msgs = portal.categories.joins(:translations).find_by(help_center_category_translations: { locale: 'en', name: 'Messages' }) || portal.categories.new(account: account, portal: portal)
        cat_msgs.update!(api_reference: true, status: :active, visibility: :everyone, featured: true, position: 5)

        # Articles
        
        # Introduction -> Authentication
        art_auth = cat_intro.articles.joins(:translations).find_by(help_center_article_translations: { locale: 'en', title: 'Authentication' }) || cat_intro.articles.new(portal: portal)
        art_auth.update!(
          account: account,
          article_type: :standard,
          status: :published,
          visibility: :everyone,
          primary_category_id: cat_intro.id,
          configurations: {}
        )
        art_auth.categories << cat_intro unless art_auth.categories.include?(cat_intro)

        art_inbox_list = cat_inbox.articles.joins(:translations).find_by(help_center_article_translations: { locale: 'en', title: 'List Inboxes' }) || cat_inbox.articles.new(portal: portal)
        art_inbox_list.update!(
          account: account,
          article_type: :api_endpoint,
          status: :published,
          visibility: :everyone,
          primary_category_id: cat_inbox.id,
          configurations: {
            "api_method" => "GET",
            "api_endpoint" => "/v1/inboxes",
            "api_parameters" => [
              { "name" => "page", "type" => "integer", "description" => "Page number", "required" => false },
              { "name" => "per_page", "type" => "integer", "description" => "Items per page", "required" => false }
            ],
            "api_responses" => [
              { 
                "status" => 200, 
                "description" => "Success", 
                "body" => "{\n  \"data\": [\n    {\n      \"id\": \"inbox_123\",\n      \"name\": \"Support Team\",\n      \"created_at\": \"2026-07-03T10:00:00Z\"\n    }\n  ],\n  \"meta\": {\n    \"current_page\": 1,\n    \"total_pages\": 1,\n    \"total_count\": 1\n  }\n}" 
              }
            ]
          }
        )
        art_inbox_list.categories << cat_inbox unless art_inbox_list.categories.include?(cat_inbox)

        art_cust_list = cat_cust.articles.joins(:translations).find_by(help_center_article_translations: { locale: 'en', title: 'List Customers' }) || cat_cust.articles.new(portal: portal)
        art_cust_list.update!(
          account: account,
          article_type: :api_endpoint,
          status: :published,
          visibility: :everyone,
          primary_category_id: cat_cust.id,
          configurations: {
            "api_method" => "GET",
            "api_endpoint" => "/v1/customers",
            "api_parameters" => [
              { "name" => "page", "type" => "integer", "description" => "Page number", "required" => false },
              { "name" => "per_page", "type" => "integer", "description" => "Items per page", "required" => false }
            ],
            "api_responses" => [
              { 
                "status" => 200, 
                "description" => "Success", 
                "body" => "{\n  \"data\": [\n    {\n      \"id\": \"cust_987\",\n      \"name\": \"John Doe\",\n      \"email\": \"john@example.com\",\n      \"created_at\": \"2026-07-03T10:00:00Z\"\n    }\n  ],\n  \"meta\": {\n    \"current_page\": 1,\n    \"total_pages\": 2,\n    \"total_count\": 20\n  }\n}" 
              }
            ]
          }
        )
        art_cust_list.categories << cat_cust unless art_cust_list.categories.include?(cat_cust)

        art_cust_create = cat_cust.articles.joins(:translations).find_by(help_center_article_translations: { locale: 'en', title: 'Create Customer' }) || cat_cust.articles.new(portal: portal)
        art_cust_create.update!(
          account: account,
          article_type: :api_endpoint,
          status: :published,
          visibility: :everyone,
          primary_category_id: cat_cust.id,
          configurations: {
            "api_method" => "POST",
            "api_endpoint" => "/v1/customers",
            "api_parameters" => [
              { "name" => "name", "type" => "string", "description" => "Name of the customer", "required" => true },
              { "name" => "email", "type" => "string", "description" => "Email address of the customer", "required" => true }
            ],
            "api_responses" => [
              { 
                "status" => 200, 
                "description" => "Success", 
                "body" => "{\n  \"data\": {\n    \"id\": \"cust_987\",\n    \"name\": \"John Doe\",\n    \"email\": \"john@example.com\",\n    \"created_at\": \"2026-07-03T10:00:00Z\"\n  }\n}" 
              }
            ]
          }
        )
        art_cust_create.categories << cat_cust unless art_cust_create.categories.include?(cat_cust)
        
        # Conversations List
        art_conv_list = cat_conv.articles.joins(:translations).find_by(help_center_article_translations: { locale: 'en', title: 'List Conversations' }) || cat_conv.articles.new(portal: portal)
        art_conv_list.update!(
          account: account,
          article_type: :api_endpoint,
          status: :published,
          visibility: :everyone,
          primary_category_id: cat_conv.id,
          configurations: {
            "api_method" => "GET",
            "api_endpoint" => "/v1/conversations",
            "api_parameters" => [
              { "name" => "status", "type" => "string", "description" => "Filter by status (open, resolved, etc.)", "required" => false },
              { "name" => "inbox_id", "type" => "string", "description" => "Filter by inbox UUID", "required" => false },
              { "name" => "page", "type" => "integer", "description" => "Page number", "required" => false },
              { "name" => "per_page", "type" => "integer", "description" => "Items per page", "required" => false }
            ],
            "api_responses" => [
              { 
                "status" => 200, 
                "description" => "Success", 
                "body" => "{\n  \"data\": [\n    {\n      \"id\": \"conv_12345\",\n      \"status\": \"open\",\n      \"customer_id\": \"cust_987\",\n      \"inbox_id\": \"inbox_1\",\n      \"created_at\": \"2026-07-03T10:00:00Z\"\n    }\n  ],\n  \"meta\": {\n    \"current_page\": 1,\n    \"total_pages\": 5,\n    \"total_count\": 50\n  }\n}" 
              },
              {
                "status" => 401,
                "description" => "Unauthorized",
                "body" => "{\n  \"error\": \"Unauthorized\",\n  \"message\": \"Invalid or missing API key\"\n}"
              }
            ]
          }
        )
        art_conv_list.categories << cat_conv unless art_conv_list.categories.include?(cat_conv)

        # Create Conversation
        art_conv_create = cat_conv.articles.joins(:translations).find_by(help_center_article_translations: { locale: 'en', title: 'Create Conversation' }) || cat_conv.articles.new(portal: portal)
        art_conv_create.update!(
          account: account,
          article_type: :api_endpoint,
          status: :published,
          visibility: :everyone,
          primary_category_id: cat_conv.id,
          configurations: {
            "api_method" => "POST",
            "api_endpoint" => "/v1/conversations",
            "api_parameters" => [
              { "name" => "inbox_id", "type" => "string", "description" => "ID of the inbox", "required" => true },
              { "name" => "customer_id", "type" => "string", "description" => "ID of the customer", "required" => true },
              { "name" => "status", "type" => "string", "description" => "Status of the conversation", "required" => false }
            ],
            "api_responses" => [
              { 
                "status" => 200, 
                "description" => "Success", 
                "body" => "{\n  \"data\": {\n    \"id\": \"conv_12345\",\n    \"status\": \"open\",\n    \"customer_id\": \"cust_987\",\n    \"inbox_id\": \"inbox_1\",\n    \"created_at\": \"2026-07-03T10:00:00Z\"\n  }\n}" 
              },
              {
                "status" => 422,
                "description" => "Unprocessable Entity",
                "body" => "{\n  \"error\": \"Validation Failed\",\n  \"details\": {\n    \"inbox_id\": [\"can't be blank\"]\n  }\n}"
              }
            ]
          }
        )
        art_conv_create.categories << cat_conv unless art_conv_create.categories.include?(cat_conv)

        # Messages List
        art_msg_list = cat_msgs.articles.joins(:translations).find_by(help_center_article_translations: { locale: 'en', title: 'List Messages' }) || cat_msgs.articles.new(portal: portal)
        art_msg_list.update!(
          account: account,
          article_type: :api_endpoint,
          status: :published,
          visibility: :everyone,
          primary_category_id: cat_msgs.id,
          configurations: {
            "api_method" => "GET",
            "api_endpoint" => "/v1/conversations/:conversation_id/messages",
            "api_parameters" => [
              { "name" => "page", "type" => "integer", "description" => "Page number", "required" => false },
              { "name" => "per_page", "type" => "integer", "description" => "Items per page", "required" => false }
            ],
            "api_responses" => [
              { 
                "status" => 200, 
                "description" => "Success", 
                "body" => "{\n  \"data\": [\n    {\n      \"id\": \"msg_111\",\n      \"content\": \"Hello, I need help!\",\n      \"message_type\": \"incoming\",\n      \"created_at\": \"2026-07-03T10:05:00Z\"\n    }\n  ],\n  \"meta\": {\n    \"current_page\": 1,\n    \"total_pages\": 1,\n    \"total_count\": 1\n  }\n}" 
              },
              {
                "status" => 404,
                "description" => "Not Found",
                "body" => "{\n  \"error\": \"Not Found\",\n  \"message\": \"Conversation not found\"\n}"
              }
            ]
          }
        )
        art_msg_list.categories << cat_msgs unless art_msg_list.categories.include?(cat_msgs)

        # Send Message
        art_msg_send = cat_msgs.articles.joins(:translations).find_by(help_center_article_translations: { locale: 'en', title: 'Send Message' }) || cat_msgs.articles.new(portal: portal)
        art_msg_send.update!(
          account: account,
          article_type: :api_endpoint,
          status: :published,
          visibility: :everyone,
          primary_category_id: cat_msgs.id,
          configurations: {
            "api_method" => "POST",
            "api_endpoint" => "/v1/conversations/:conversation_id/messages",
            "api_parameters" => [
              { "name" => "content", "type" => "string", "description" => "The message content", "required" => true },
              { "name" => "message_type", "type" => "string", "description" => "Type of message (incoming, outgoing)", "required" => false }
            ],
            "api_responses" => [
              { 
                "status" => 200, 
                "description" => "Success", 
                "body" => "{\n  \"data\": {\n    \"id\": \"msg_222\",\n    \"content\": \"We will look into this right away.\",\n    \"message_type\": \"outgoing\",\n    \"created_at\": \"2026-07-03T10:10:00Z\"\n  }\n}" 
              },
              {
                "status" => 422,
                "description" => "Unprocessable Entity",
                "body" => "{\n  \"error\": \"Validation Failed\",\n  \"details\": {\n    \"content\": [\"can't be blank\"]\n  }\n}"
              }
            ]
          }
        )
        art_msg_send.categories << cat_msgs unless art_msg_send.categories.include?(cat_msgs)

        # Setup Translations for Categories and Articles
        locales = {
          en: {
            intro: { name: "Getting Started", desc: "Start building with the Deskbolic API." },
            inbox: { name: "Inboxes", desc: "Manage your team inboxes." },
            cust: { name: "Customers", desc: "Manage your customers." },
            conv: { name: "Conversations", desc: "Manage conversations programmatically." },
            msgs: { name: "Messages", desc: "Manage and send messages." },
            auth: { 
              title: "Authentication", 
              content: <<~'HTML'
                <p>The Deskbolic API uses API keys to authenticate requests. You can view and manage your API keys in the Deskbolic Dashboard under <strong>Settings -&gt; Developer API Keys</strong>.</p>
                <p>Your API requests must include the <code>X-Api-Key</code> HTTP header.</p>
                <p>If you wish to receive localized responses, you can also send the <code>X-Locale</code> header or <code>Accept-Language</code> header (e.g., <code>es</code> for Spanish).</p>
                <pre><code>curl -H "X-Api-Key: YOUR_API_KEY" \
     -H "X-Locale: en" \
     https://api.deskbolic.com/v1/conversations</code></pre>
              HTML
            },
            inbox_list: {
              title: "List Inboxes",
              content: <<~'HTML'
                <p>Returns a paginated list of inboxes in your account.</p>
                <h3>Examples</h3>
                <p><strong>cURL</strong></p>
                <pre><code>curl -H "X-Api-Key: YOUR_API_KEY" https://api.deskbolic.com/v1/inboxes</code></pre>
              HTML
            },
            cust_list: {
              title: "List Customers",
              content: <<~'HTML'
                <p>Returns a paginated list of customers in your account.</p>
                <h3>Examples</h3>
                <p><strong>cURL</strong></p>
                <pre><code>curl -H "X-Api-Key: YOUR_API_KEY" https://api.deskbolic.com/v1/customers</code></pre>
              HTML
            },
            cust_create: {
              title: "Create Customer",
              content: <<~'HTML'
                <p>Creates a new customer in your account.</p>
                <h3>Examples</h3>
                <p><strong>cURL</strong></p>
                <pre><code>curl -X POST https://api.deskbolic.com/v1/customers \
     -H "X-Api-Key: YOUR_API_KEY" \
     -H "Content-Type: application/json" \
     -d '{"name": "John Doe", "email": "john@example.com"}'</code></pre>
              HTML
            },
            conv_list: { 
              title: "List Conversations", 
              content: <<~'HTML'
                <p>Returns a paginated list of conversations in your account. Use this to sync conversation histories or build custom dashboards.</p>
                <p><strong>Pagination Note</strong>: This endpoint supports pagination via the <code>page</code> and <code>per_page</code> query parameters. The response will include a <code>meta</code> block containing <code>current_page</code>, <code>total_pages</code>, and <code>total_count</code>.</p>
                <h3>Examples</h3>
                <p><strong>cURL</strong></p>
                <pre><code>curl -H "X-Api-Key: YOUR_API_KEY" https://api.deskbolic.com/v1/conversations?status=open&amp;page=1</code></pre>
                <p><strong>Ruby</strong></p>
                <pre><code>require 'httparty'
response = HTTParty.get("https://api.deskbolic.com/v1/conversations", headers: { "X-Api-Key" => "YOUR_API_KEY" })
puts response.body</code></pre>
                <p><strong>JavaScript (Node.js)</strong></p>
                <pre><code>fetch('https://api.deskbolic.com/v1/conversations', {
  headers: { 'X-Api-Key': 'YOUR_API_KEY' }
})
.then(res => res.json())
.then(data => console.log(data));</code></pre>
              HTML
            },
            conv_create: { 
              title: "Create Conversation", 
              content: <<~'HTML'
                <p>Creates a new conversation in a specific inbox for a customer.</p>
                <h3>Examples</h3>
                <p><strong>cURL</strong></p>
                <pre><code>curl -X POST https://api.deskbolic.com/v1/conversations \
     -H "X-Api-Key: YOUR_API_KEY" \
     -H "Content-Type: application/json" \
     -d '{"inbox_id": "INBOX_UUID", "customer_id": "CUSTOMER_UUID", "status": "open"}'</code></pre>
              HTML
            },
            msg_list: { 
              title: "List Messages", 
              content: <<~'HTML'
                <p>Returns a paginated list of messages for a specific conversation.</p>
                <h3>Examples</h3>
                <p><strong>cURL</strong></p>
                <pre><code>curl -H "X-Api-Key: YOUR_API_KEY" https://api.deskbolic.com/v1/conversations/CONV_UUID/messages</code></pre>
              HTML
            },
            msg_send: { 
              title: "Send Message", 
              content: <<~'HTML'
                <p>Sends a new message in a specific conversation.</p>
                <h3>Examples</h3>
                <p><strong>cURL</strong></p>
                <pre><code>curl -X POST https://api.deskbolic.com/v1/conversations/CONV_UUID/messages \
     -H "X-Api-Key: YOUR_API_KEY" \
     -H "Content-Type: application/json" \
     -d '{"content": "Hello world!"}'</code></pre>
              HTML
            }
          },
          es: {
            intro: { name: "Empezando", desc: "Comience a construir con la API de Deskbolic." },
            inbox: { name: "Bandejas de entrada", desc: "Gestiona las bandejas de entrada." },
            cust: { name: "Clientes", desc: "Gestiona los clientes." },
            conv: { name: "Conversaciones", desc: "Gestione conversaciones de forma programática." },
            msgs: { name: "Mensajes", desc: "Gestione y envíe mensajes." },
            auth: { 
              title: "Autenticación", 
              content: <<~'HTML'
                <p>La API de Deskbolic usa claves API para autenticar solicitudes. Puede gestionar sus claves API en el panel de Deskbolic bajo <strong>Ajustes -&gt; Claves API</strong>.</p>
                <p>Sus peticiones deben incluir el encabezado HTTP <code>X-Api-Key</code>.</p>
                <p>Si desea respuestas localizadas, envíe el encabezado <code>X-Locale</code> o <code>Accept-Language</code> (por ejemplo, <code>es</code>).</p>
                <pre><code>curl -H "X-Api-Key: YOUR_API_KEY" \
     -H "X-Locale: es" \
     https://api.deskbolic.com/v1/conversations</code></pre>
              HTML
            },
            inbox_list: {
              title: "Listar Bandejas de entrada",
              content: <<~'HTML'
                <p>Devuelve una lista paginada de bandejas de entrada.</p>
                <h3>Ejemplos</h3>
                <p><strong>cURL</strong></p>
                <pre><code>curl -H "X-Api-Key: YOUR_API_KEY" https://api.deskbolic.com/v1/inboxes</code></pre>
              HTML
            },
            cust_list: {
              title: "Listar Clientes",
              content: <<~'HTML'
                <p>Devuelve una lista paginada de clientes.</p>
                <h3>Ejemplos</h3>
                <p><strong>cURL</strong></p>
                <pre><code>curl -H "X-Api-Key: YOUR_API_KEY" https://api.deskbolic.com/v1/customers</code></pre>
              HTML
            },
            cust_create: {
              title: "Crear Cliente",
              content: <<~'HTML'
                <p>Crea un nuevo cliente.</p>
              HTML
            },
            conv_list: { 
              title: "Listar Conversaciones", 
              content: <<~'HTML'
                <p>Devuelve una lista paginada de conversaciones. Útil para sincronizar historiales o crear paneles personalizados.</p>
                <h3>Ejemplos</h3>
                <p><strong>cURL</strong></p>
                <pre><code>curl -H "X-Api-Key: YOUR_API_KEY" https://api.deskbolic.com/v1/conversations?status=open&amp;page=1</code></pre>
              HTML
            },
            conv_create: { 
              title: "Crear Conversación", 
              content: "<p>Crea una nueva conversación. Envíe los parámetros necesarios en el cuerpo de la solicitud (JSON).</p>" 
            },
            msg_list: { 
              title: "Listar Mensajes", 
              content: "<p>Devuelve una lista paginada de mensajes para una conversación.</p>" 
            },
            msg_send: { 
              title: "Enviar Mensaje", 
              content: "<p>Envía un nuevo mensaje en una conversación específica.</p>" 
            }
          },
          fr: {
            intro: { name: "Pour Commencer", desc: "Commencez à construire avec l'API Deskbolic." },
            inbox: { name: "Boîtes de réception", desc: "Gérez vos boîtes de réception." },
            cust: { name: "Clients", desc: "Gérez vos clients." },
            conv: { name: "Conversations", desc: "Gérez les conversations de manière programmatique." },
            msgs: { name: "Messages", desc: "Gérez et envoyez des messages." },
            auth: { 
              title: "Authentification", 
              content: <<~'HTML'
                <p>L'API Deskbolic utilise des clés API pour l'authentification. Vous pouvez gérer vos clés API dans le tableau de bord Deskbolic sous <strong>Paramètres -&gt; Clés API</strong>.</p>
                <p>Vos requêtes doivent inclure l'en-tête HTTP <code>X-Api-Key</code>.</p>
                <p>Si vous souhaitez des réponses localisées, envoyez l'en-tête <code>X-Locale</code> ou <code>Accept-Language</code> (par exemple, <code>fr</code>).</p>
                <pre><code>curl -H "X-Api-Key: YOUR_API_KEY" \
     -H "X-Locale: fr" \
     https://api.deskbolic.com/v1/conversations</code></pre>
              HTML
            },
            inbox_list: {
              title: "Lister les boîtes de réception",
              content: <<~'HTML'
                <p>Retourne une liste paginée de boîtes de réception.</p>
                <h3>Exemples</h3>
                <p><strong>cURL</strong></p>
                <pre><code>curl -H "X-Api-Key: YOUR_API_KEY" https://api.deskbolic.com/v1/inboxes</code></pre>
              HTML
            },
            cust_list: {
              title: "Lister les clients",
              content: <<~'HTML'
                <p>Retourne une liste paginée de clients.</p>
                <h3>Exemples</h3>
                <p><strong>cURL</strong></p>
                <pre><code>curl -H "X-Api-Key: YOUR_API_KEY" https://api.deskbolic.com/v1/customers</code></pre>
              HTML
            },
            cust_create: {
              title: "Créer un client",
              content: <<~'HTML'
                <p>Crée un nouveau client.</p>
              HTML
            },
            conv_list: { 
              title: "Lister les conversations", 
              content: <<~'HTML'
                <p>Retourne une liste paginée de conversations. Utile pour synchroniser les historiques ou créer des tableaux de bord personnalisés.</p>
                <h3>Exemples</h3>
                <p><strong>cURL</strong></p>
                <pre><code>curl -H "X-Api-Key: YOUR_API_KEY" https://api.deskbolic.com/v1/conversations?status=open&amp;page=1</code></pre>
              HTML
            },
            conv_create: { 
              title: "Créer une conversation", 
              content: "<p>Crée une nouvelle conversation.</p>" 
            },
            msg_list: { 
              title: "Lister les messages", 
              content: "<p>Retourne une liste paginée de messages pour une conversation.</p>" 
            },
            msg_send: { 
              title: "Envoyer un message", 
              content: "<p>Envoie un nouveau message dans une conversation spécifique.</p>" 
            }
          }
        }

        locales.each do |locale, trans|
          I18n.with_locale(locale) do
            cat_intro.update!(name: trans[:intro][:name], description: trans[:intro][:desc])
            cat_inbox.update!(name: trans[:inbox][:name], description: trans[:inbox][:desc])
            cat_cust.update!(name: trans[:cust][:name], description: trans[:cust][:desc])
            cat_conv.update!(name: trans[:conv][:name], description: trans[:conv][:desc])
            cat_msgs.update!(name: trans[:msgs][:name], description: trans[:msgs][:desc])

            art_auth.update!(title: trans[:auth][:title], content: trans[:auth][:content])
            art_inbox_list.update!(title: trans[:inbox_list][:title], content: trans[:inbox_list][:content])
            art_cust_list.update!(title: trans[:cust_list][:title], content: trans[:cust_list][:content])
            art_cust_create.update!(title: trans[:cust_create][:title], content: trans[:cust_create][:content])
            art_conv_list.update!(title: trans[:conv_list][:title], content: trans[:conv_list][:content])
            art_conv_create.update!(title: trans[:conv_create][:title], content: trans[:conv_create][:content])
            art_msg_list.update!(title: trans[:msg_list][:title], content: trans[:msg_list][:content])
            art_msg_send.update!(title: trans[:msg_send][:title], content: trans[:msg_send][:content])
          end
        end
      end
      
      puts "API Documentation seeded successfully!"
    end
  end
end
