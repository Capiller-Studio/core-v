# frozen_string_literal: true

module Seeds
  module Data
    module ApiDocs
      module GettingStarted
        def self.category
          {
            key: :getting_started,
            icon_key: "book-open",
            position: 1,
            api_reference: false,
            translations: {
              en: {
                name: "Getting Started",
                description: "Essential concepts, base URLs, authentication headers, rate limits, and error handling for Capiller Rely API."
              },
              de: {
                name: "Erste Schritte",
                description: "Grundlegende Konzepte, Basis-URLs, Authentifizierungs-Header, Ratenbegrenzungen und Fehlerbehandlung für die Capiller Rely-API."
              },
              es: {
                name: "Primeros Pasos",
                description: "Conceptos esenciales, URLs base, encabezados de autenticación, límites de tasa y manejo de errores para la API de Capiller Rely."
              },
              fr: {
                name: "Mise en route",
                description: "Concepts essentiels, URL de base, en-têtes d'authentification, limites de débit et gestion des erreurs pour l'API Capiller Rely."
              },
              "pt-BR": {
                name: "Primeiros Passos",
                description: "Conceitos essenciais, URLs base, cabeçalhos de autenticação, limites de taxa e tratamento de erros para a API Capiller Rely."
              },
              ar: {
                name: "البدء والأساسيات",
                description: "المفاهيم الأساسية، عناوين URL الأساسية، ترويسات المصادقة، حدود المعدل ومعالجة الأخطاء لواجهة برمجة تطبيقات Capiller Rely."
              },
              ko: {
                name: "시작하기",
                description: "Capiller Rely API의 기본 개념, 기본 URL, 인증 헤더, 전송률 제한 및 오류 처리 가이드입니다."
              }
            }
          }
        end

        def self.articles
          [
            {
              key: :overview,
              article_type: :standard,
              position: 1,
              translations: {
                en: {
                  title: "API Overview & Architecture",
                  content: <<~HTML
                    <p>Welcome to the <strong>Capiller Rely REST API</strong> documentation. The Capiller Rely API provides programmatic access to your customer support platform, inboxes, omnichannel conversations, customer profiles, automation workflows, and real-time messaging capabilities.</p>
                    <h3>Base URL</h3>
                    <pre><code class="language-http">https://api-rely.capiller.com/v1</code></pre>
                    <h3>API Conventions</h3>
                    <ul>
                      <li><strong>Protocol:</strong> HTTPS is strictly required for all API endpoints.</li>
                      <li><strong>Format:</strong> All request bodies and response payloads are formatted in standard <code>application/json</code>.</li>
                      <li><strong>HTTP Methods:</strong> Standard verbs (<code>GET</code>, <code>POST</code>, <code>PATCH</code>, <code>DELETE</code>) are used according to REST principles.</li>
                      <li><strong>Response Envelope:</strong> Successful responses are enveloped in <code>{"data": ...}</code> with optional <code>{"meta": ...}</code> for paginated collections.</li>
                    </ul>
                  HTML
                },
                de: {
                  title: "API-Übersicht & Architektur",
                  content: <<~HTML
                    <p>Willkommen zur Dokumentation der <strong>Capiller Rely REST-API</strong>. Die Capiller Rely-API bietet programmatischen Zugriff auf Ihre Kundensupport-Plattform, Postfächer, Omnichannel-Konversationen, Kundenprofile und Echtzeit-Nachrichten.</p>
                    <h3>Basis-URL</h3>
                    <pre><code class="language-http">https://api-rely.capiller.com/v1</code></pre>
                    <h3>API-Konventionen</h3>
                    <ul>
                      <li><strong>Protokoll:</strong> HTTPS ist für alle API-Endpunkte obligatorisch.</li>
                      <li><strong>Format:</strong> Alle Anfragen und Antworten sind in <code>application/json</code> formatiert.</li>
                      <li><strong>Antwort-Hülle:</strong> Erfolgreiche Antworten sind in <code>{"data": ...}</code> eingebettet.</li>
                    </ul>
                  HTML
                },
                es: {
                  title: "Descripción General y Arquitectura de la API",
                  content: <<~HTML
                    <p>Bienvenido a la documentación de la <strong>API REST de Capiller Rely</strong>. La API de Capiller Rely proporciona acceso programático a su plataforma de soporte al cliente, bandejas de entrada, conversaciones omnicanal y perfiles de clientes.</p>
                    <h3>URL Base</h3>
                    <pre><code class="language-http">https://api-rely.capiller.com/v1</code></pre>
                    <h3>Convenciones</h3>
                    <ul>
                      <li><strong>Protocolo:</strong> HTTPS es obligatorio para todos los puntos finales.</li>
                      <li><strong>Formato:</strong> Formato estándar <code>application/json</code>.</li>
                      <li><strong>Envoltorio de Respuesta:</strong> Las respuestas exitosas están envueltas en <code>{"data": ...}</code>.</li>
                    </ul>
                  HTML
                },
                fr: {
                  title: "Vue d'ensemble et Architecture de l'API",
                  content: <<~HTML
                    <p>Bienvenue dans la documentation de l'<strong>API REST Capiller Rely</strong>. L'API Capiller Rely permet d'interagir par programmation avec votre plateforme de support client, vos boîtes de réception et vos conversations omnicanales.</p>
                    <h3>URL de base</h3>
                    <pre><code class="language-http">https://api-rely.capiller.com/v1</code></pre>
                    <h3>Conventions</h3>
                    <ul>
                      <li><strong>Protocole:</strong> HTTPS est obligatoire sur tous les points de terminaison.</li>
                      <li><strong>Format:</strong> Les requêtes et réponses utilisent <code>application/json</code>.</li>
                    </ul>
                  HTML
                },
                "pt-BR": {
                  title: "Visão Geral e Arquitetura da API",
                  content: <<~HTML
                    <p>Bem-vindo à documentação da <strong>API REST Capiller Rely</strong>. A API Capiller Rely fornece acesso programático à sua plataforma de atendimento, caixas de entrada, conversas multicanal e perfis de clientes.</p>
                    <h3>URL Base</h3>
                    <pre><code class="language-http">https://api-rely.capiller.com/v1</code></pre>
                    <h3>Convenções</h3>
                    <ul>
                      <li><strong>Protocolo:</strong> HTTPS é obrigatório em todos os endpoints.</li>
                      <li><strong>Formato:</strong> Todas as requisições e respostas utilizam <code>application/json</code>.</li>
                    </ul>
                  HTML
                },
                ar: {
                  title: "نظرة عامة على واجهة برمجة التطبيقات والبنية",
                  content: <<~HTML
                    <p>مرحبًا بك في وثائق <strong>واجهة برمجة تطبيقات Capiller Rely REST</strong>. تتيح لك واجهة برمجة التطبيقات الوصول البرمجي إلى منصة دعم العملاء، وصناديق الوارد، والمحادثات متعددة القنوات، وملفات تعريف العملاء.</p>
                    <h3>عنوان URL الأساسي</h3>
                    <pre><code class="language-http">https://api-rely.capiller.com/v1</code></pre>
                    <h3>معايير واجهة برمجة التطبيقات</h3>
                    <ul>
                      <li><strong>البروتوكول:</strong> HTTPS مطلوب لجميع نقاط النهاية.</li>
                      <li><strong>التنسيق:</strong> يتم تنسيق جميع البيانات عبر <code>application/json</code>.</li>
                    </ul>
                  HTML
                },
                ko: {
                  title: "API 개요 및 아키텍처",
                  content: <<~HTML
                    <p><strong>Capiller Rely REST API</strong> 설명서에 오신 것을 환영합니다. Capiller Rely API를 통해 고객 지원 플랫폼, 받은 편지함, 옴니채널 대화, 고객 프로필 및 실시간 메시징 기능을 프로그래밍 방식으로 제어할 수 있습니다.</p>
                    <h3>기본 URL</h3>
                    <pre><code class="language-http">https://api-rely.capiller.com/v1</code></pre>
                    <h3>API 표준</h3>
                    <ul>
                      <li><strong>프로토콜:</strong> 모든 API 엔드포인트는 HTTPS가 필수입니다.</li>
                      <li><strong>형식:</strong> 모든 요청 및 응답 페이로드는 <code>application/json</code> 형식입니다.</li>
                      <li><strong>응답 래퍼:</strong> 성공적인 응답은 <code>{"data": ...}</code> 래퍼로 반환됩니다.</li>
                    </ul>
                  HTML
                }
              }
            },
            {
              key: :authentication,
              article_type: :standard,
              position: 2,
              translations: {
                en: {
                  title: "Authentication & API Keys",
                  content: <<~HTML
                    <p>The Capiller Rely API supports two primary methods of authentication depending on your integration type:</p>
                    <h3>1. API Key Authentication (Server-to-Server)</h3>
                    <p>For backend integrations, server scripts, and webhooks, generate an API Access Token from <strong>Settings &rarr; API &amp; Integrations</strong> in your Capiller Rely dashboard. Pass the token in the <code>X-Api-Key</code> request header:</p>
                    <pre><code class="language-bash">curl -H "X-Api-Key: dsk_live_abc123xyz" \\
     https://api-rely.capiller.com/v1/conversations</code></pre>
                    <h3>2. JWT Bearer Token (Mobile &amp; User Sessions)</h3>
                    <p>For mobile apps and client-side applications, authenticate via <code>POST /v1/auth/login</code> to obtain a JWT token, then pass it as a Bearer token:</p>
                    <pre><code class="language-bash">curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \\
     https://api-rely.capiller.com/v1/me</code></pre>
                    <h3>Multi-Tenant Account Context</h3>
                    <p>If your user belongs to multiple workspaces, specify which workspace to target using the <code>X-Account-Id</code> header:</p>
                    <pre><code class="language-http">X-Account-Id: 3e1da942-7725-4c19-84da-2a8dde4948b9</code></pre>
                  HTML
                },
                de: {
                  title: "Authentifizierung & API-Schlüssel",
                  content: <<~HTML
                    <p>Die Capiller Rely-API unterstützt zwei Authentifizierungsmethoden:</p>
                    <h3>1. API-Schlüssel-Authentifizierung (Server-to-Server)</h3>
                    <p>Übergeben Sie Ihren API-Schlüssel im <code>X-Api-Key</code>-Header:</p>
                    <pre><code class="language-bash">curl -H "X-Api-Key: dsk_live_abc123xyz" https://api-rely.capiller.com/v1/conversations</code></pre>
                    <h3>2. JWT Bearer Token</h3>
                    <p>Übergeben Sie den Token im <code>Authorization: Bearer &lt;token&gt;</code>-Header.</p>
                    <h3>Mandanten-Kontext</h3>
                    <p>Geben Sie bei Bedarf den <code>X-Account-Id</code>-Header an.</p>
                  HTML
                },
                es: {
                  title: "Autenticación y Claves de API",
                  content: <<~HTML
                    <p>La API de Capiller Rely admite dos métodos principales de autenticación:</p>
                    <h3>1. Clave de API (Servidor a Servidor)</h3>
                    <p>Pase la clave en el encabezado <code>X-Api-Key</code>:</p>
                    <pre><code class="language-bash">curl -H "X-Api-Key: dsk_live_abc123xyz" https://api-rely.capiller.com/v1/conversations</code></pre>
                    <h3>2. Token JWT</h3>
                    <p>Pase el token en el encabezado <code>Authorization: Bearer &lt;token&gt;</code>.</p>
                  HTML
                },
                fr: {
                  title: "Authentification et Clés API",
                  content: <<~HTML
                    <p>L'API Capiller Rely prend en charge deux méthodes d'authentification:</p>
                    <h3>1. Clé API (Serveur à Serveur)</h3>
                    <pre><code class="language-bash">curl -H "X-Api-Key: dsk_live_abc123xyz" https://api-rely.capiller.com/v1/conversations</code></pre>
                    <h3>2. Jeton JWT</h3>
                    <pre><code class="language-bash">curl -H "Authorization: Bearer YOUR_JWT_TOKEN" https://api-rely.capiller.com/v1/me</code></pre>
                  HTML
                },
                "pt-BR": {
                  title: "Autenticação e Chaves de API",
                  content: <<~HTML
                    <p>A API Capiller Rely suporta dois métodos de autenticação:</p>
                    <h3>1. Chave de API (Servidor para Servidor)</h3>
                    <pre><code class="language-bash">curl -H "X-Api-Key: dsk_live_abc123xyz" https://api-rely.capiller.com/v1/conversations</code></pre>
                    <h3>2. Token JWT</h3>
                    <pre><code class="language-bash">curl -H "Authorization: Bearer YOUR_JWT_TOKEN" https://api-rely.capiller.com/v1/me</code></pre>
                  HTML
                },
                ar: {
                  title: "المصادقة ومفاتيح واجهة برمجة التطبيقات",
                  content: <<~HTML
                    <p>تدعم واجهة برمجة تطبيقات Capiller Rely طريقتين للمصادقة:</p>
                    <h3>1. المصادقة عبر مفتاح API (من خادم إلى خادم)</h3>
                    <pre><code class="language-bash">curl -H "X-Api-Key: dsk_live_abc123xyz" https://api-rely.capiller.com/v1/conversations</code></pre>
                    <h3>2. رمز JWT</h3>
                    <pre><code class="language-bash">curl -H "Authorization: Bearer YOUR_JWT_TOKEN" https://api-rely.capiller.com/v1/me</code></pre>
                  HTML
                },
                ko: {
                  title: "인증 및 API 키",
                  content: <<~HTML
                    <p>Capiller Rely API는 두 가지 인증 방식을 지원합니다:</p>
                    <h3>1. API 키 인증 (서버 간 통신)</h3>
                    <pre><code class="language-bash">curl -H "X-Api-Key: dsk_live_abc123xyz" https://api-rely.capiller.com/v1/conversations</code></pre>
                    <h3>2. JWT Bearer 토큰 인증</h3>
                    <pre><code class="language-bash">curl -H "Authorization: Bearer YOUR_JWT_TOKEN" https://api-rely.capiller.com/v1/me</code></pre>
                  HTML
                }
              }
            },
            {
              key: :errors_and_rate_limits,
              article_type: :standard,
              position: 3,
              translations: {
                en: {
                  title: "Errors, Rate Limits & Status Codes",
                  content: <<~HTML
                    <p>Capiller Rely uses conventional HTTP response codes to indicate the success or failure of an API request.</p>
                    <h3>HTTP Status Codes</h3>
                    <table>
                      <thead><tr><th>Code</th><th>Meaning</th><th>Description</th></tr></thead>
                      <tbody>
                        <tr><td><code>200 OK</code></td><td>Success</td><td>Request completed successfully.</td></tr>
                        <tr><td><code>201 Created</code></td><td>Resource Created</td><td>New record created successfully.</td></tr>
                        <tr><td><code>400 Bad Request</code></td><td>Invalid Request</td><td>Malformed parameters or body.</td></tr>
                        <tr><td><code>401 Unauthorized</code></td><td>Authentication Required</td><td>Missing or invalid API key/JWT.</td></tr>
                        <tr><td><code>402 Payment Required</code></td><td>Subscription Inactive</td><td>Account subscription limit reached or expired.</td></tr>
                        <tr><td><code>403 Forbidden</code></td><td>Access Denied</td><td>Permission denied or API channel feature not enabled.</td></tr>
                        <tr><td><code>404 Not Found</code></td><td>Not Found</td><td>The requested resource does not exist.</td></tr>
                        <tr><td><code>422 Unprocessable</code></td><td>Validation Error</td><td>Validation failed on resource attributes.</td></tr>
                        <tr><td><code>500 Server Error</code></td><td>Internal Error</td><td>Server encountered an error.</td></tr>
                      </tbody>
                    </table>
                    <h3>Error Response Format</h3>
                    <pre><code class="language-json">{
  "errors": [
    {
      "code": "not_found",
      "message": "Resource not found"
    }
  ]
}</code></pre>
                  HTML
                },
                de: {
                  title: "Fehlercodes, Ratenbegrenzungen & Status",
                  content: <<~HTML
                    <p>Capiller Rely verwendet standardmäßige HTTP-Statuscodes für den Erfolg oder Misserfolg von Anfragen.</p>
                    <h3>HTTP-Statuscodes</h3>
                    <ul>
                      <li><code>200 OK</code>: Erfolgreiche Anfrage.</li>
                      <li><code>401 Unauthorized</code>: Ungültiger API-Schlüssel.</li>
                      <li><code>403 Forbidden</code>: Keine Berechtigung.</li>
                      <li><code>404 Not Found</code>: Ressource nicht gefunden.</li>
                      <li><code>422 Unprocessable</code>: Validierungsfehler.</li>
                    </ul>
                  HTML
                },
                es: {
                  title: "Códigos de Error y Límites de Tasa",
                  content: <<~HTML
                    <p>Capiller Rely utiliza códigos de respuesta HTTP convencionales para indicar el éxito o fracaso de las solicitudes.</p>
                    <ul>
                      <li><code>200 OK</code>: Solicitud exitosa.</li>
                      <li><code>401 Unauthorized</code>: Clave de API no válida o ausente.</li>
                      <li><code>404 Not Found</code>: Recurso no encontrado.</li>
                      <li><code>422 Unprocessable</code>: Error de validación.</li>
                    </ul>
                  HTML
                },
                fr: {
                  title: "Codes d'erreur et Limites de Débit",
                  content: <<~HTML
                    <p>Capiller Rely utilise les codes d'état HTTP conventionnels pour indiquer le résultat des requêtes API.</p>
                    <ul>
                      <li><code>200 OK</code>: Succès.</li>
                      <li><code>401 Unauthorized</code>: Clé API manquante ou invalide.</li>
                      <li><code>404 Not Found</code>: Ressource introuvable.</li>
                      <li><code>422 Unprocessable</code>: Erreur de validation.</li>
                    </ul>
                  HTML
                },
                "pt-BR": {
                  title: "Códigos de Erro e Limites de Taxa",
                  content: <<~HTML
                    <p>A Capiller Rely utiliza códigos HTTP padrão para indicar o sucesso ou falha das requisições.</p>
                    <ul>
                      <li><code>200 OK</code>: Sucesso.</li>
                      <li><code>401 Unauthorized</code>: Chave de API inválida ou ausente.</li>
                      <li><code>404 Not Found</code>: Recurso não encontrado.</li>
                      <li><code>422 Unprocessable</code>: Erro de validação.</li>
                    </ul>
                  HTML
                },
                ar: {
                  title: "رموز الأخطاء وحدود المعدل",
                  content: <<~HTML
                    <p>يستخدم Capiller Rely رموز استجابة HTTP القياسية لتوضيح نجاح أو فشل الطلبات.</p>
                    <ul>
                      <li><code>200 OK</code>: نجاح الطلب.</li>
                      <li><code>401 Unauthorized</code>: المصادقة غير صالحة.</li>
                      <li><code>404 Not Found</code>: المورد غير موجود.</li>
                      <li><code>422 Unprocessable</code>: خطأ في التحقق من صحة البيانات.</li>
                    </ul>
                  HTML
                },
                ko: {
                  title: "오류 코드 및 속도 제한",
                  content: <<~HTML
                    <p>Capiller Rely은 표준 HTTP 상태 코드를 사용하여 요청 성공 여부를 전달합니다.</p>
                    <ul>
                      <li><code>200 OK</code>: 요청 성공.</li>
                      <li><code>401 Unauthorized</code>: 유효하지 않거나 누락된 인증 키.</li>
                      <li><code>404 Not Found</code>: 리소스를 찾을 수 없음.</li>
                      <li><code>422 Unprocessable</code>: 유효성 검사 실패.</li>
                    </ul>
                  HTML
                }
              }
            },
            {
              key: :locales_and_i18n,
              article_type: :standard,
              position: 4,
              translations: {
                en: {
                  title: "Localization & Multi-Language (X-Locale)",
                  content: <<~HTML
                    <p>The Capiller Rely API natively supports 7 international languages. Error messages, validation feedback, and localized attributes are returned in the requested language.</p>
                    <h3>Supported Locales</h3>
                    <ul>
                      <li><code>en</code>: English (Default)</li>
                      <li><code>de</code>: German (Deutsch)</li>
                      <li><code>es</code>: Spanish (Espa&ntilde;ol)</li>
                      <li><code>fr</code>: French (Fran&ccedil;ais)</li>
                      <li><code>pt-BR</code>: Portuguese - Brazil (Portugu&ecirc;s)</li>
                      <li><code>ar</code>: Arabic (العربية) - RTL supported</li>
                      <li><code>ko</code>: Korean (한국어)</li>
                    </ul>
                    <h3>Specifying Locale Header</h3>
                    <p>Pass the <code>X-Locale</code> header with any API request:</p>
                    <pre><code class="language-bash">curl -H "X-Api-Key: YOUR_API_KEY" \\
     -H "X-Locale: de" \\
     https://api-rely.capiller.com/v1/conversations</code></pre>
                  HTML
                },
                de: {
                  title: "Lokalisierung & Mehrsprachigkeit (X-Locale)",
                  content: <<~HTML
                    <p>Die Capiller Rely-API unterstützt nativ 7 Sprachen über den <code>X-Locale</code>-Header (z.B. <code>de</code>, <code>en</code>, <code>fr</code>, <code>es</code>).</p>
                    <pre><code class="language-bash">curl -H "X-Api-Key: YOUR_API_KEY" -H "X-Locale: de" https://api-rely.capiller.com/v1/conversations</code></pre>
                  HTML
                },
                es: {
                  title: "Localización e Idiomas (X-Locale)",
                  content: <<~HTML
                    <p>La API de Capiller Rely admite 7 idiomas internacionales a través del encabezado <code>X-Locale</code>.</p>
                    <pre><code class="language-bash">curl -H "X-Api-Key: YOUR_API_KEY" -H "X-Locale: es" https://api-rely.capiller.com/v1/conversations</code></pre>
                  HTML
                },
                fr: {
                  title: "Localisation et Multilinguisme (X-Locale)",
                  content: <<~HTML
                    <p>L'API Capiller Rely prend en charge 7 langues grâce à l'en-tête <code>X-Locale</code>.</p>
                    <pre><code class="language-bash">curl -H "X-Api-Key: YOUR_API_KEY" -H "X-Locale: fr" https://api-rely.capiller.com/v1/conversations</code></pre>
                  HTML
                },
                "pt-BR": {
                  title: "Localização e Múltiplos Idiomas (X-Locale)",
                  content: <<~HTML
                    <p>A API Capiller Rely suporta nativamente 7 idiomas através do cabeçalho <code>X-Locale</code>.</p>
                    <pre><code class="language-bash">curl -H "X-Api-Key: YOUR_API_KEY" -H "X-Locale: pt-BR" https://api-rely.capiller.com/v1/conversations</code></pre>
                  HTML
                },
                ar: {
                  title: "التعريب واللغات المتعددة (X-Locale)",
                  content: <<~HTML
                    <p>تدعم واجهة برمجة تطبيقات Capiller Rely 7 لغات عالمية عبر ترويسة <code>X-Locale</code>.</p>
                    <pre><code class="language-bash">curl -H "X-Api-Key: YOUR_API_KEY" -H "X-Locale: ar" https://api-rely.capiller.com/v1/conversations</code></pre>
                  HTML
                },
                ko: {
                  title: "다국어 및 로케일 지원 (X-Locale)",
                  content: <<~HTML
                    <p>Capiller Rely API는 <code>X-Locale</code> 헤더를 통해 7개 언어를 지원합니다.</p>
                    <pre><code class="language-bash">curl -H "X-Api-Key: YOUR_API_KEY" -H "X-Locale: ko" https://api-rely.capiller.com/v1/conversations</code></pre>
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
