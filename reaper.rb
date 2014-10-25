require 'octokit'
require 'colorize'
require 'time'
require 'pry'

class Reaper
  STALE_THRESHOLD = 3600 * 24 * 30 * 3 # 3 months

  def initialize
    # Look for .netrc credentials first; if they don't exist then prompt
    # for login.
    # TODO
    @client = Octokit::Client.new(access_token: ENV['GITHUB_ACCESS_TOKEN'])
  end

  def run!
    repo_path = 'amfeng/todidnt'

    puts "=== Reaping: #{repo_path}".bold.white

    now = Time.now

    # Fetch issues in ascending updated order.
    options = {
      sort: :updated,
      direction: :asc
    }

    @client.list_issues(repo_path, options).each do |issue|
      issue = Issue.new(issue)

      # Skip if this task has already been closed or has a do-not-reap tag.
      next if issue.closed?
      next if issue.labels.include?('do-not-reap')

      # Break out of the whole loop if the issue's updated date is outside
      # the range.
      break if issue.updated_at > now - STALE_THRESHOLD

      # If there's a to-reap tag, close it. Else, add a to-reap tag and
      # a warning comment.
      # FIXME: The timeout for closing an issue after a warning should be
      # customizable and not based on run-time of the reaper (e.g. running
      # reaper should be idempotent).

      if issue.labels.include?('to-reap')
        # TODO: Add force-all flag.

        puts "Issue ##{issue.number}: #{issue.title}"
        print "Close issue? [Y]es, [N]o, or n[E]ver: ".yellow
        input = $stdin.gets.chomp.downcase
        case input
        when 'y'
          #issue.close
          puts "Issue was reaped.".green
        when 'n'
          puts "OK, skipping.".red
        when 'e'
          #issue.labels << 'do-not-reap'
          #issue.save
          puts "OK, added `do-not-reap`.".green
        end

      else
        #issue.labels << 'to-reap'
        #issue.comment("reaper warning")
        #issue.save
        puts "Added `to-reap` to #{issue.number}"
      end
    end
  end

  class Issue
    attr_accessor :labels

    def initialize(issue)
      @issue = issue
      @labels = issue.labels.map(&:name)
    end

    def close
      # TODO
    end

    def closed?
      @issue.state == 'closed'
    end

    def comment(comment)
      # TODO
    end

    def save
      # TODO
    end

    def method_missing(meth, *args, &block)
      @issue.send(meth, *args, &block)
    end
  end
end

reaper = Reaper.new
reaper.run!

