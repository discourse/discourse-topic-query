# frozen_string_literal: true

require 'rails_helper'

def list_for_topics(topics)
  output = "<ul>"
  output += "\n" if topics.length > 1
  output += topics.map do |topic|
    "<li><a href=\"#{topic.url.gsub("http:", '')}\">#{topic.title}</a></li>"
  end.join("\n")
  output += "\n" if topics.length > 1
  output += "</ul>"
end

describe 'plugin post process' do
  fab!(:user) { Fabricate(:admin) }

  before do
    SiteSetting.discourse_topic_query_enabled = true
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
    it 'processes it' do
      post = create_post(user: user, raw: "[topics]\n[/topics]")
      post.rebake!
      post.reload

      expect(post.custom_fields[DiscourseTopicQuery::HAS_TOPIC_QUERY]).to eq('t')
      expect(post.cooked).to include("<div class=\"discourse-topic-query\">#{list_for_topics(Topic.all)}</div>")
    end

    context 'using tags attribute markup' do
      it 'processes it' do
        tag_1 = Fabricate(:tag)
        tag_2 = Fabricate(:tag)
        tag_3 = Fabricate(:tag)
        topic_1 = Fabricate(:topic, tags: [tag_1], created_at: 3.minutes.ago)
        topic_2 = Fabricate(:topic, tags: [tag_1], created_at: 2.minutes.ago)
        topic_3 = Fabricate(:topic, tags: [tag_2], created_at: 1.minutes.ago)
        Fabricate(:topic, tags: [tag_3])

        post = create_post(user: user, raw: "[topics tags=#{tag_1.name},#{tag_2.name} order=created]\n[/topics]")
        post.rebake!
        post.reload

        expect(post.custom_fields[DiscourseTopicQuery::HAS_TOPIC_QUERY]).to eq('t')
        expect(post.cooked).to include("<div class=\"discourse-topic-query\" data-tags=\"#{tag_1.name},#{tag_2.name}\" data-order=\"created\">#{list_for_topics([topic_3,topic_2,topic_1])}</div>")
      end
    end

    context 'using exceptTopicIds attribute markup' do
      it 'processes it' do
        topic = create_topic(user: user)
        post = create_post(user: user, topic: topic, raw: "[topics exceptTopicIds=#{topic.id}]\n[/topics]")
        post.rebake!
        post.reload

        expect(post.custom_fields[DiscourseTopicQuery::HAS_TOPIC_QUERY]).to eq('t')
        expect(post.cooked).to include("<div class=\"discourse-topic-query\" data-excepttopicids=\"#{topic.id}\"></div>")
      end
    end
  end

  context 'rebaking all posts with topic query' do
    it 'rebakes the post' do
      post = create_post(user: user, raw: "[topics order=\"created\"]\n[/topics]")

      post.rebake!
      post.reload

      expect(Topic.all.count).to eq(1)
      expect(post.cooked).to include("<div class=\"discourse-topic-query\" data-order=\"created\">#{list_for_topics(Topic.all)}</div>")

      Fabricate(:topic)
      DiscourseTopicQuery.rebake_posts_with_topic_query
      post.reload

      expect(Topic.all.count).to eq(2)
      expect(post.cooked).to include("<div class=\"discourse-topic-query\" data-order=\"created\">#{list_for_topics(Topic.order('created_at DESC').all)}</div>")
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
        post = create_post(user: user, raw: "[topics order=\"created\"]\n[/topics]")

        post.rebake!
        post.reload

        expect(post.cooked).to include("<div class=\"discourse-topic-query\" data-order=\"created\">#{list_for_topics(Topic.all)}</div>")
      end
    end

    context 'is not member of allowed groups' do
      it 'processes the post' do
        post = create_post(user: user, raw: "[topics order=\"created\"]\n[/topics]")

        post.rebake!
        post.reload

        expect(post.cooked).to include("<div class=\"discourse-topic-query\" data-order=\"created\"></div>")
      end
    end
  end
end
