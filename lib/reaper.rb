#!/bin/env ruby
# encoding: utf-8

require 'colorize'
require 'time'

require 'reaper/version'
require 'reaper/issue'
require 'reaper/client'

module Reaper
  REAPER_WARNING = <<-eos
    Hi! This is a friendly (automated) warning from the reaper that this
    issue hasn't been updated in 3 months and will be automatically closed
    in 1 week.

    If you don't want this to be closed yet, you should remove the `to-reap`
    label and the 3 month timeout will reset. If you never want this to be
    reaped, add the label `do-not-reap`.

    Thanks! (:
  eos

  class CLI
    def initialize(opts)
      @client = Reaper::Client.instance
      @client.set_repo(opts[:repository])

      @stale_threshold = 3600 * 24 * 30 * opts[:threshold]
    end

    def run!
      now = Time.now

      puts "Welcome to Reaper! ⟝⦆ (fetching from `#{@client.repo}`)".white.bold

      # Fetch issues in ascending updated order.
      options = {
        sort: :updated,
        direction: :asc
      }

      issues = @client.list_issues(options)
      issues_reaped = false

      issues.each do |issue|
        issue = Reaper::Issue.new(issue)

        # Skip if this task has already been closed or has a do-not-reap tag.
        next if issue.closed?
        next if issue.labels.include?('do-not-reap')

        # If there's a to-reap tag, close it. Else, add a to-reap tag and
        # a warning comment.
        # FIXME: The timeout for closing an issue after a warning should be
        # customizable and not based on run-time of the reaper (e.g. running
        # reaper should be idempotent).

        puts "\n"
        if issue.labels.include?('to-reap')
          issues_reaped = true
          # TODO: Add force-all flag.

          issue_action(issue, "Close issue?") do |issue|
            issue.reap
            puts "Issue was reaped.".green
          end
        else
          # Break out of the whole loop if the issue's updated date is outside
          # the range.
          break if issue.updated_at > now - @stale_threshold

          issues_reaped = true
          issue_action(issue, "Add warning?") do |issue|
            issue.warn(Reaper::REAPER_WARNING)
            puts "Added `to-reap` to #{issue.number}"
          end
        end
      end

      if issues_reaped
        puts "Nice, you're done!".green
      else
        puts "No reap-able issues, woohoo!".green
      end
    end

    def issue_action(issue, action_label, show_title=true, &blk)
      puts "= Issue ##{issue.number}: #{issue.title}".white if show_title
      print "#{action_label} [Y]es, [N]o, or n[E]ver: ".yellow
      input = $stdin.gets.chomp.downcase

      case input
      when 'y'
        yield issue
      when 'n'
        puts "OK, skipping.".red
      when 'e'
        issue.protect
        puts "OK, added `do-not-reap`.".green
      else
        issue_action(issue, action_label, false, &blk)
      end
    end
  end
end
