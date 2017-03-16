#!/bin/env ruby
# encoding: utf-8

require 'colorize'
require 'time'

require 'reaper/version'
require 'reaper/issue'
require 'reaper/client'

module Reaper
  class CLI
    def initialize(opts)
      @client = Reaper::Client.instance
      @client.set_repo(opts[:repository])

      @stale_threshold = 3600 * 24 * 30 * opts[:threshold]
      stale_string = opts[:threshold] == 1 ? '1 month' : "#{opts[:threshold]} months"

      @warning_delay = 3600 * 24 * opts[:delay]
      warning_string = opts[:delay] == 1 ? '1 day' : "#{opts[:threshold]} days"

      @skip_confirm = opts[:skip]
      @reaper_warning =
        "Hi! This is a friendly (automated) warning from the reaper that " \
        "this issue hasn't been updated in #{stale_string} and will be " \
        "automatically closed in #{warning_string}." \
        "\n\n" \
        "If you don't want this to be closed yet, you should remove the " \
        "`to-reap` label and the timeout will reset. If you never want this " \
        "to be reaped, add the label `do-not-reap`." \
        "\n\n" \
        "Thanks! :)"
    end

    def run!
      now = Time.now

      puts "Welcome to Reaper! ⟝⦆ (fetching from `#{@client.repo}`)".white.bold
      issues_reaped = false

      # Fetch to-reap issues.

      options = {
        labels: 'to-reap'
      }

      puts "Finding issues to reap..."
      issues = @client.list_issues(options)
      issues.each do |issue|
        issue = Reaper::Issue.new(issue)

        # latest_event is slow so let's dot dot dot to indicate progress
        print '.'
        last_to_reap_event = issue.latest_event do |event|
          event.event == 'labeled' && event.label.name == 'to-reap'
        end
        unless last_to_reap_event
          puts "Race condition: no reap label on #{issue.number}"
          next
        end
        next if last_to_reap_event.created_at > now - @warning_delay

        issues_reaped = true
        puts ""
        issue_action(issue, "Close issue?", @skip_confirm) do |issue|
          issue.reap
          puts "Issue #{issue.number} was reaped.".green
        end
      end

      # Fetch issues in ascending updated order.
      options = {
        sort: :updated,
        direction: :asc
      }

      puts "Finding next reapable issues..."
      issues = @client.list_issues(options)
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

        # Break out of the whole loop if the issue's updated date is outside
        # the range.
        break if issue.updated_at > now - @stale_threshold

        issues_reaped = true
        issue_action(issue, "Add warning?", @skip_confirm) do |issue|
          issue.warn(@reaper_warning)
          puts "Added `to-reap` to #{issue.number}"
        end
      end

      if issues_reaped
        puts "Nice, you're done!".green
      else
        puts "No reap-able issues, woohoo!".green
      end
    end

    def issue_action(issue, action_label, skip_confirm=false, show_title=true, &blk)
      return yield issue if skip_confirm

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
