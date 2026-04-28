# frozen_string_literal: true

module HelpCenter
  class CategoryTranslation < ShardRecord
    belongs_to :category, class_name: "HelpCenter::Category"
    
    validates :locale, presence: true
    validates :name, presence: true
  end
end
