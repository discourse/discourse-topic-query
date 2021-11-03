# frozen_string_literal: true

# name: discourse-topic-query
# about: Allows to list specific topics in a post using [topics params][/topics] block
# version: 0.0.1
# authors: j.jaffeux
# required_version: 2.7.0
# transpile_js: true

enabled_site_setting :discourse_topic_query_enabled

after_initialize do
  module ::DiscourseTopicQuery
    PLUGIN_NAME ||= "discourse-topic-query"
    HAS_TOPIC_QUERY ||= :has_topic_query
    VALID_ATTRIBUTES ||= {
      'tags' => { type: :array },
      'topicids' => { type: :array, mapping: :topic_ids },
      'excepttopicids' => { type: :array, mapping: :except_topic_ids },
      'ascending' => { type: :string },
      'order' => { type: :string },
      'status' => { type: :string },
      'assigned' => { type: :string },
      'category' => { type: :string },
    }

    class Engine < ::Rails::Engine
      engine_name PLUGIN_NAME
      isolate_namespace DiscourseTopicQuery
    end

    class Error < StandardError; end

    def self.rebake_posts_with_topic_query
      if !SiteSetting.discourse_topic_query_enabled
        return
      end

      PostCustomField.joins(:post).where(name: HAS_TOPIC_QUERY).find_each do |pcf|
        if !pcf.post
          pcf.destroy!
        else
          pcf.post.rebake!
        end
      end
    end
  end

  register_post_custom_field_type(DiscourseTopicQuery::HAS_TOPIC_QUERY, :boolean)

  add_to_class(:user, :can_use_discourse_topic_query?) do
    if defined?(@can_use_discourse_topic_query)
      return @can_use_discourse_topic_query
    end
    @can_use_discourse_topic_query = begin
      return true if staff?
      allowed_groups = SiteSetting.discourse_topic_query_allowed_on_groups.to_s.split('|').compact
      allowed_groups.present? && groups.where(id: allowed_groups).exists?
    rescue StandardError
      false
    end
  end

  on(:before_post_process_cooked) do |doc, post|
    topic_queries = doc.css('.discourse-topic-query')
    topic_queries.each do |fragment|
      if !post&.user&.can_use_discourse_topic_query?
        next
      end

      options = { limit: 20 }
      DiscourseTopicQuery::VALID_ATTRIBUTES.each do |attribute, params|
        value = fragment.attributes["data-#{attribute}"]&.value
        attribute = params[:mapping] || attribute.to_sym
        if value
          case params[:type]
          when :array
            options[attribute] = value.split(',')
          when :string
            options[attribute] = value
          end
        end
      end

      query = TopicQuery.new(post.user, options)
      topics_list = query.latest_results.map do |topic|
        "<li><a href=\"#{topic.url}\">#{topic.title}</a></li>"
      end

      if topics_list.count > 0
        fragment.inner_html = "<ul>#{topics_list.join}</ul>"
      end
    end

    if topic_queries.empty?
      if post.custom_fields[DiscourseTopicQuery::HAS_TOPIC_QUERY]
        PostCustomField
          .where(post_id: post.id, name: DiscourseTopicQuery::HAS_TOPIC_QUERY)
          .delete_all
      end
    else
      if !post.custom_fields[DiscourseTopicQuery::HAS_TOPIC_QUERY]
        post.upsert_custom_fields(DiscourseTopicQuery::HAS_TOPIC_QUERY => true)
      end
    end
  end
end
