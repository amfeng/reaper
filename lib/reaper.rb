#!/bin/env ruby
# encoding: utf-8

require 'colorize'
require 'time'

require 'reaper/issue'
require 'reaper/client'

module Reaper
  STALE_THRESHOLD = 3600 * 24 * 30 * 3 # 3 months

  class CLI
    def initialize
      @client = Reaper::Client.instance
    end

    def run!
      repo_path = 'amfeng/reaper'
      now = Time.now

      puts "Welcome to Reaper! ⟝⦆ (fetching from `#{repo_path}`)".white.bold

      # Fetch issues in ascending updated order.
      options = {
        sort: :updated,
        direction: :asc
      }

      issues = @client.list_issues
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

          puts "= Issue ##{issue.number}: #{issue.title}".white
          print "Close issue? [Y]es, [N]o, or n[E]ver: ".yellow
          input = $stdin.gets.chomp.downcase
          case input
          when 'y'
            issue.close
            puts "Issue was reaped.".green
          when 'n'
            puts "OK, skipping.".red
          when 'e'
            issue.labels << 'do-not-reap'
            issue.labels -= ['to-reap']
            issue.save
            puts "OK, added `do-not-reap`.".green
          end
        else
          # Break out of the whole loop if the issue's updated date is outside
          # the range.
          break if issue.updated_at > now - Reaper::STALE_THRESHOLD

          issues_reaped = true
          puts "= Issue ##{issue.number}: #{issue.title}".white
          print "Add warning? [Y]es, [N]o, or n[E]ver: ".yellow
          input = $stdin.gets.chomp.downcase

          case input
          when 'y'
            issue.labels << 'to-reap'
            issue.comment("reaper warning")
            issue.save
            puts "Added `to-reap` to #{issue.number}"
          when 'n'
            puts "OK, skipping.".red
          when 'e'
            issue.labels << 'do-not-reap'
            issue.labels -= ['to-reap']
            issue.save
            puts "OK, added `do-not-reap`.".green
          end
        end
      end

      unless issues_reaped
        puts "No reap-able issues, woohoo!".green
      end
    end
  end
end
