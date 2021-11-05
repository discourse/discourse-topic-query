# frozen_string_literal: true

module DiscourseTopicQuery
  class PostTemplate
    def initialize(post, grouped_search, options = {})
      @post = post
      @grouped_search = grouped_search
      @options = options
    end

    def build
      output = <<~TEMPLATE
        <li class="topic">
          <span class="first-line">
            #{build_topic_title(@post, @options)}
          </span>
          #{render_second_line(@post, @options)}
          #{build_post_body(@post, @options)}
        </li>
      TEMPLATE
    end

    private

    def render_second_line(post, options)
      unless options[:hide_tags] && options[:hide_category]
        output = <<~TEMPLATE
          <span class="second-line">
        TEMPLATE

        unless options[:hide_category]
          output += CategoryBadge.html_for(post.topic.category)
        end

        unless options[:hide_tags]
          output += build_topic_tags(post, options)
        end

        output += <<~TEMPLATE
          </span>
        TEMPLATE
      end
    end

    def build_post_body(post, options)
      if options[:excerpt_length] > 0
        <<~TEMPLATE
          <span class="blurb excerpt">#{@grouped_search.blurb(post)}</span>
        TEMPLATE
      end
    end

    def build_topic_title(post, options)
      <<~TEMPLATE
        <a href="#{post.topic.url}">
          <span class="topic-title">
            #{post.topic.title}
          </span>
        </a>
      TEMPLATE
    end

    def render_tag(post, tag, is_pm:)
      is_pm_only = tag.topic_count == 0 && tag.pm_topic_count > 0

      path = nil
      if is_pm || is_pm_only
        path = "/u/#{post.user.username}/messages/tags/#{tag.name}"
      else
        path = "/tag/#{tag.name}"
      end

      classes = ["discourse-tag"]
      if SiteSetting.tag_style
        classes << SiteSetting.tag_style
      end

      <<~TEMPLATE
        <a href="#{path}" data-tag-name="#{tag.name}" class="#{classes.join(' ')}">
          #{tag.name}
        </a>
      TEMPLATE
    end

    def build_topic_tags(post, options)
      topic = post.topic
      is_pm = topic.archetype == Archetype.private_message

      <<~TEMPLATE
        <div class="discourse-tags">
          #{topic.tags.map { |tag| render_tag(post, tag, is_pm: is_pm) }.join(" ")}
        </div>
      TEMPLATE
    end
  end
end
