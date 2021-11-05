# frozen_string_literal: true

# name: discourse-topic-query
# about: Allows to list specific topics in a post using [query params][/query] block
# version: 0.0.1
# authors: j.jaffeux
# required_version: 2.7.0
# transpile_js: true

enabled_site_setting :discourse_topic_query_enabled
register_asset 'stylesheets/common.scss'

after_initialize do
  module ::DiscourseTopicQuery
    PLUGIN_NAME ||= "discourse-topic-query"
    HAS_TOPIC_QUERY ||= :has_topic_query

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

  %w[../lib/post_template.rb].each do |path|
    load File.expand_path(path, __FILE__)
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
    next if !post.user

    topic_queries = doc.css('.discourse-topic-query')
    topic_queries.each do |fragment|
      if !post&.user&.can_use_discourse_topic_query?
        next
      end

      query = fragment.attributes['data-query']&.value

      if !query
        next
      end

      hide_tags = fragment.attributes['data-hide-tags']&.value == 'true'
      hide_category = fragment.attributes['data-hide-category']&.value == 'true'

      excerpt_length = (fragment.attributes['data-excerpt-length']&.value || 200).to_i
      excerpt_length = [excerpt_length, 300].min

      search = Search.new(query, guardian: Guardian.new(post.user), blurb_length: excerpt_length)
      grouped_results = search.execute

      if !grouped_results
        next
      end

      results = grouped_results.posts.map do |found_post|
        if found_post == post
          next
        end

        DiscourseTopicQuery::PostTemplate.new(
          found_post,
          grouped_results,
          excerpt_length: excerpt_length,
          hide_tags: hide_tags,
          hide_category: hide_category,
        ).build
      end

      if results.count > 0
        classes = []
        classes << "force-list" if excerpt_length == 0
        fragment.inner_html = "<ul class=\"#{classes.join(" ")}\">#{results.join}</ul>"
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
