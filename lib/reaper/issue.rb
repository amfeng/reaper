module Reaper
  class Issue
    attr_accessor :state, :title, :body, :labels

    def initialize(issue)
      @issue = issue

      @title = @issue.title
      @body = @issue.body
      @state = @issue.state
      @labels = issue.labels.map(&:name)
      @buffered_comments = []

      @client = Reaper::Client.instance
    end

    # Action methods

    def reap
      @labels << 'reaped'
      @labels -= ['to-reap']
      @client.close_issue(@issue.number, labels: @labels)
    end

    def warn(warning)
      @labels << 'to-reap'
      comment(warning)
      save
    end

    def protect
      @labels << 'do-not-reap'
      @labels -= ['to-reap']
      save
    end

    def closed?
      @state == 'closed'
    end

    private

    def comment(comment)
      @buffered_comments << comment
    end

    def save
      @client.update_issue(@issue.number, @title, @body, labels: @labels)

      @buffered_comments.each do |comment|
        @client.add_comment(@issue.number, comment)
      end
      @buffered_comments = []
    end

    def method_missing(meth, *args, &block)
      @issue.send(meth, *args, &block)
    end
  end
end
