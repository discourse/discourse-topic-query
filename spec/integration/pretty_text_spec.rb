# frozen_string_literal: true

require 'rails_helper'

describe 'plugin post process' do
  fab!(:user) { Fabricate(:admin) }
  fab!(:category_1) { Fabricate(:category) }
  fab!(:tag_1) { Fabricate(:tag) }
  fab!(:post_1) {
    SearchIndexer.enable
    create_post(category: category_1, tags: [tag_1.name])
  }

  before do
    SiteSetting.tagging_enabled = true
    SiteSetting.discourse_topic_query_enabled = true
    SearchIndexer.enable
    Jobs.run_immediately!
  end

  context 'creating a post with no markup' do
    it 'doesn’t do anything' do
      post = create_post(user: user)

      post.rebake!
      post.reload

      expect(post.custom_fields[DiscourseTopicQuery::HAS_TOPIC_QUERY]).to be_blank
    end
  end

  context 'creating a post with markup' do
    context 'without query' do
      it 'does nothing' do
        post = create_post(user: user, raw: "[query]")
        post.rebake!
        post.reload

        expect(post.custom_fields[DiscourseTopicQuery::HAS_TOPIC_QUERY]).to be(nil)
        expect(post.cooked).to eq("<p>[query]</p>")
      end
    end

    context 'with query' do
      it 'processes the query' do
        post_2 = create_post(user: user, raw: "[query=\"##{tag_1.name}\"]")
        post_2.rebake!
        post_2.reload

        expect(post_2.custom_fields[DiscourseTopicQuery::HAS_TOPIC_QUERY]).to eq('t')

        expect(post_2.cooked).to include <<~HTML
          <a href=\"#{post_1.topic.url.gsub('http:', '')}\">
            <span class=\"topic-title\">
              #{post_1.topic.title}
            </span>
          </a>
        HTML

        expect(post_2.cooked).to include <<~HTML
          <a href="/tag/#{tag_1.name}" data-tag-name="#{tag_1.name}" class="discourse-tag simple">
            #{tag_1.name}
          </a>
        HTML

        expect(post_2.cooked).to include <<~HTML
          <span class="blurb excerpt">#{post_1.raw}</span>
        HTML
      end

      context 'hideTags=true' do
        it 'hides the tags' do
          post_2 = create_post(user: user, raw: "[query=\"##{tag_1.name}\" hideTags=true]")
          post_2.rebake!
          post_2.reload

          expect(post_2.cooked).to include('<span class="second-line">')
          expect(post_2.cooked).to_not include <<~HTML
            <div class="discourse-tags">
          HTML
        end
      end

      context 'excerptLength=0' do
        it 'removes the excerpt and forces list' do
          post_2 = create_post(user: user, raw: "[query=\"##{tag_1.name}\" excerptLength=0]")
          post_2.rebake!
          post_2.reload

          expect(post_2.cooked).to include('<ul class="force-list">')
          expect(post_2.cooked).to_not include('<span class="blurb excerpt">')
        end
      end

      context 'hideCategory=true' do
        it 'hides the category' do
          post_2 = create_post(user: user, raw: "[query=\"##{tag_1.name}\" hideCategory=false]")
          post_2.rebake!
          post_2.reload

          expect(post_2.cooked).to include('<span class="second-line">')
          expect(post_2.cooked).to_not include <<~HTML
            "badge-category"
          HTML
        end
      end

      context 'hideCategory=true and hideTag=true' do
        it 'hides the category' do
          post_2 = create_post(user: user, raw: "[query=\"##{tag_1.name}\" hideCategory=false hideTag=true]")
          post_2.rebake!
          post_2.reload

          expect(post_2.cooked).to_not include <<~HTML
            <div class="second-line">
          HTML
        end
      end
    end
  end

  context 'rebaking all posts with topic query' do
    it 'rebakes the post' do
      post = create_post(user: user, raw: "[query=\"##{tag_1.name}\"]")
      post.rebake!
      post.reload

      expect(Topic.all.count).to eq(2)

      new_topic = create_post(user: user, tags: [tag_1.name]).topic
      DiscourseTopicQuery.rebake_posts_with_topic_query
      post.reload

      expect(Topic.all.count).to eq(3)
      expect(post.cooked).to include("#{new_topic.title}")
    end
  end

  context 'post’s user is not staff' do
    fab!(:user) { Fabricate(:user) }

    context 'is member of allowed groups' do
      fab!(:group) { Fabricate(:group) }

      before do
        SiteSetting.discourse_topic_query_allowed_on_groups = group.id
        group.add(user)
      end

      it 'processes the post' do
        post = create_post(user: user, raw: "[query=\"##{tag_1.name}\"]")
        post.rebake!
        post.reload

        expect(post.cooked).to include(post_1.topic.title)
      end
    end

    context 'is not member of allowed groups' do
      it 'processes the post' do
        post = create_post(user: user, raw: "[query=\"##{tag_1.name}\"]")

        expect(post.cooked).to_not include(post_1.topic.title)
      end
    end
  end
end
