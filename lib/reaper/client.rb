require 'octokit'
require 'singleton'

module Reaper
  class Client
    include Singleton

    attr_accessor :client, :repo

    def initialize
      # Look for .netrc credentials first; if they don't exist then prompt
      # for login.
      # TODO
      @client = Octokit::Client.new(access_token: ENV['GITHUB_ACCESS_TOKEN'])
      @repo = nil

      # TODO: Add things other than Github.
    end

    def set_repo(repo)
      @repo = repo
    end

    def method_missing(meth, *args, &block)
      raise "Must provide a Github repository." unless @repo

      @client.send(meth, *([@repo] + args), &block)
    end
  end
end
