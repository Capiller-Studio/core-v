FactoryBot.define do
  factory :email_template do
    account
    name { "Template #{SecureRandom.hex(4)}" }
    body { "<html><body>Hello</body></html>" }
    template_type { :conversation_reply }
  end
end
