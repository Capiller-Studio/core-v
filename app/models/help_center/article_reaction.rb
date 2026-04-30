# frozen_string_literal: true

# == Schema Information
#
# Table name: help_center_article_reactions
#
#  id            :uuid             not null, primary key
#  ip_address    :string
#  reaction_type :integer          not null
#  session_id    :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  article_id    :uuid             not null
#
# Indexes
#
#  index_help_center_article_reactions_on_article_id                  (article_id)
#  index_help_center_article_reactions_on_article_id_and_ip_address   (article_id,ip_address) UNIQUE
#  index_help_center_article_reactions_on_reaction_type               (reaction_type)
#
# Foreign Keys
#
#  fk_rails_...  (article_id => help_center_articles.id) ON DELETE => cascade
#
module HelpCenter
  class ArticleReaction < ShardRecord
    belongs_to :article, class_name: "HelpCenter::Article"

    # reaction_type is the emoji-based sentiment:
    #   happy (0)   😃 — article was helpful
    #   neutral (1) 😐 — article was somewhat helpful
    #   sad (2)     😔 — article was not helpful
    enum :reaction_type, { happy: 0, neutral: 1, sad: 2 }

    validates :reaction_type, presence: true
    validates :ip_address, uniqueness: { scope: :article_id }, allow_nil: true
  end
end
