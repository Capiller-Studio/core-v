# frozen_string_literal: true

module HelpCenter
  class ArticleTranslation < ShardRecord
    belongs_to :article, class_name: "HelpCenter::Article"
    
    validates :locale, presence: true
    validates :title, presence: true
  end
end
