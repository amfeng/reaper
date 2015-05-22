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
      access_token = ENV['GITHUB_ACCESS_TOKEN']

      raise "Missing Github access token." if access_token.nil?

      @client = Octokit::Client.new(access_token: access_token)
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
