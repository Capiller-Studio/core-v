# frozen_string_literal: true

module Seeds
  module Data
    module ApiDocs
      module Attachments
        def self.category
          {
            key: :attachments,
            icon_key: "paperclip",
            position: 9,
            api_reference: true,
            translations: {
              en: {
                name: "Attachments & Media",
                description: "Endpoints to upload media files, images, documents, and generate direct S3 pre-signed upload URLs."
              },
              de: {
                name: "Anhänge & Medien",
                description: "Endpunkte zum Hochladen von Mediendateien, Dokumenten und Generieren von direkten S3-Upload-URLs."
              },
              es: {
                name: "Archivos Adjuntos y Medios",
                description: "Puntos finales para cargar archivos multimedia, documentos y generar URLs de carga directa firmadas."
              },
              fr: {
                name: "Pièces Jointes et Médias",
                description: "Points de terminaison pour téléverser des fichiers multimédias, des documents et générer des URL de téléversement direct."
              },
              "pt-BR": {
                name: "Anexos e Mídia",
                description: "Endpoints para upload de arquivos de mídia, documentos e geração de URLs pré-assinadas para S3."
              },
              ar: {
                name: "المرفقات والوسائط",
                description: "نقاط النهاية لتحميل ملفات الوسائط والصور والمستندات وإنشاء عناوين URL موقعة مسبقًا للتحميل المباشر."
              },
              ko: {
                name: "첨부파일 및 미디어",
                description: "이미지, 문서 등 미디어 파일 직접 업로드 및 클라우드(S3) Direct Upload URL 생성 엔드포인트입니다."
              }
            }
          }
        end

        def self.articles
          [
            {
              key: :attachments_direct_upload,
              article_type: :api_endpoint,
              position: 1,
              configurations: {
                "api_method" => "POST",
                "api_endpoint" => "/v1/attachments/direct_uploads",
                "api_parameters" => [
                  { "name" => "filename", "type" => "string", "description" => "Original filename with extension (e.g. 'invoice.pdf')", "required" => true },
                  { "name" => "byte_size", "type" => "integer", "description" => "File size in bytes", "required" => true },
                  { "name" => "checksum", "type" => "string", "description" => "Base64 MD5 checksum of the file", "required" => true },
                  { "name" => "content_type", "type" => "string", "description" => "MIME type (e.g. 'application/pdf', 'image/png')", "required" => true }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Direct upload metadata",
                    "body" => "{\n  \"data\": {\n    \"id\": \"blb_123\",\n    \"key\": \"blobs/xyz987...\",\n    \"signed_id\": \"eyJfcmFpbHMiOnsibWVzc2FnZSI6...\",\n    \"direct_upload\": {\n      \"url\": \"https://s3.eu-central-1.amazonaws.com/deskbolic-storage/...\",\n      \"headers\": {\n        \"Content-Type\": \"application/pdf\"\n      }\n    }\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Generate Direct Upload Metadata",
                  content: "<p>Generates pre-signed S3/ActiveStorage direct upload headers and URL to stream large files directly to cloud storage without overloading the API gateway.</p>"
                },
                de: {
                  title: "Metadaten für Direkt-Upload generieren",
                  content: "<p>Generiert vorab signierte S3-URLs für den direkten Datei-Upload.</p>"
                },
                es: {
                  title: "Generar Metadatos de Carga Directa",
                  content: "<p>Genera encabezados y URL de carga directa pre-firmada a S3.</p>"
                },
                fr: {
                  title: "Générer les métadonnées de téléversement direct",
                  content: "<p>Génère des URL de téléversement direct S3 pré-signées.</p>"
                },
                "pt-BR": {
                  title: "Gerar Metadados para Upload Direto",
                  content: "<p>Gera URLs pré-assinadas do S3 para upload direto de arquivos.</p>"
                },
                ar: {
                  title: "إنشاء بيانات التحميل المباشر",
                  content: "<p>ينشئ عناوين URL وترويسات موقعة مسبقًا للتحميل المباشر للملفات الكبيرة إلى السحابة.</p>"
                },
                ko: {
                  title: "클라우드 Direct Upload 메타데이터 생성",
                  content: "<p>대용량 파일의 직접 업로드를 위한 S3 사전 서명된(pre-signed) 업로드 URL 및 헤더 정보를 생성합니다.</p>"
                }
              }
            },
            {
              key: :attachments_create,
              article_type: :api_endpoint,
              position: 2,
              configurations: {
                "api_method" => "POST",
                "api_endpoint" => "/v1/attachments",
                "api_parameters" => [
                  { "name" => "file", "type" => "file", "description" => "Multipart file upload binary", "required" => false },
                  { "name" => "signed_blob_id", "type" => "string", "description" => "Signed blob ID from direct upload endpoint", "required" => false },
                  { "name" => "attachment_type", "type" => "string", "description" => "'file', 'image', 'audio', 'video'", "required" => false }
                ],
                "api_responses" => [
                  {
                    "status" => 200,
                    "description" => "Attachment created",
                    "body" => "{\n  \"data\": {\n    \"id\": \"att_991\",\n    \"file_url\": \"https://cdn.capiller.com/storage/invoice.pdf\",\n    \"attachment_type\": \"file\",\n    \"extension\": \".pdf\"\n  }\n}"
                  }
                ]
              },
              translations: {
                en: {
                  title: "Upload Attachment",
                  content: "<p>Uploads a file directly via multipart form data or attaches an already uploaded signed blob to an account attachment record.</p>"
                },
                de: {
                  title: "Anhang hochladen",
                  content: "<p>Lädt eine Datei direkt über Multipart-Formulardaten hoch oder verknüpft ein signiertes Blob.</p>"
                },
                es: {
                  title: "Cargar Archivo Adjunto",
                  content: "<p>Carga un archivo directamente a través de datos de formulario multipart o adjunta un blob firmado.</p>"
                },
                fr: {
                  title: "Téléverser une pièce jointe",
                  content: "<p>Téléverse un fichier directement ou associe un blob signé.</p>"
                },
                "pt-BR": {
                  title: "Enviar Anexo",
                  content: "<p>Envia um arquivo diretamente via multipart ou vincula um blob assinado.</p>"
                },
                ar: {
                  title: "تحميل مرفق",
                  content: "<p>يقوم بتحميل ملف مباشرة أو يربط كائنًا موقعًا مسبقًا بسجل المرفق في مساحة العمل.</p>"
                },
                ko: {
                  title: "첨부파일 등록",
                  content: "<p>멀티파트(multipart) 폼으로 파일을 직접 업로드하거나 기 업로드된 서명된 Blob을 연결하여 첨부파일 레코드를 생성합니다.</p>"
                }
              }
            }
          ]
        end
      end
    end
  end
end
