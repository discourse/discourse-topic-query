# frozen_string_literal: true

class AddUniquePostCustomFieldsIndexOnHasTopicQuery < ActiveRecord::Migration[6.1]
  def change
    add_index :post_custom_fields,
              %i[post_id],
              unique: true,
              where: "name = 'has_topic_query'",
              name: :idx_post_custom_fields_has_topic_query_unique_post_id_partial
  end
end
