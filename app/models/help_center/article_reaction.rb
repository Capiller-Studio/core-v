# frozen_string_literal: true
# == Schema Information
#
# Table name: help_center_article_reactions
#
#  id            :uuid             not null, primary key
#  reaction_type :integer          not null
#  ip_address    :string
#  session_id    :string
#  article_id    :uuid             not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  idx_on_article_id_ip_address_26c6109755               (article_id,ip_address) UNIQUE
#  index_help_center_article_reactions_on_article_id     (article_id)
#  index_help_center_article_reactions_on_reaction_type  (reaction_type)
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
