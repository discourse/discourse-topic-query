# frozen_string_literal: true

module Jobs
  class RebakePostsWithTopicQuery < ::Jobs::Scheduled
    every 1.day

    def execute(args)
      DiscourseTopicQuery.rebake_posts_with_topic_query
    end
  end
end
