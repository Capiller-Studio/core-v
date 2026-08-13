FactoryBot.define do
  factory :help_center_article, class: 'HelpCenter::Article' do
    account
    portal { association :help_center_portal, account: account }
    author { association :user }
    
    sequence(:title) { |n| "Article #{n}" }
    content { "This is the content for the article." }
    
    status { :published }
    visibility { :everyone }
    article_type { :standard }
    
    configurations { {} }
  end
end
