# frozen_string_literal: true

module HelpCenter
  class CategoryTranslation < ShardRecord
    belongs_to :category, class_name: "HelpCenter::Category"

    validates :locale, presence: true
    validates :name, presence: true

    before_validation :generate_slug, on: :create
    after_save :update_descendants_slugs, if: :saved_change_to_slug?

    private

    def generate_slug
      return if slug.present? || name.blank?
      
      base = name.parameterize
      base = "category" if base.blank?
      
      if category&.parent
        parent_translation = category.parent.translations.find { |t| t.locale == locale } ||
                             category.parent.translations.find_by(locale: locale)
                             
        if parent_translation&.slug
          base = "#{parent_translation.slug}/#{base}"
        end
      end
      
      candidate = base
      counter = 1
      
      while slug_exists?(candidate)
        counter += 1
        candidate = "#{base}-#{counter}"
      end
      
      self.slug = candidate
    end

    def slug_exists?(candidate)
      return false unless category

      self.class.joins(:category)
          .where(locale: locale, slug: candidate, help_center_categories: { portal_id: category.portal_id })
          .where.not(id: id)
          .exists?
    end

    def update_descendants_slugs
      category.children.each do |child|
        child_translation = child.translations.find_by(locale: locale)
        if child_translation
          last_segment = child_translation.slug.to_s.split('/').last
          child_translation.slug = "#{slug}/#{last_segment}"
          child_translation.save!
        end
      end
    end
  end
end
