require 'octokit'
require 'singleton'

module Reaper
  class Client
    include Singleton

    attr_accessor :client

    def initialize
      # Look for .netrc credentials first; if they don't exist then prompt
      # for login.
      # TODO
      @client = Octokit::Client.new(access_token: ENV['GITHUB_ACCESS_TOKEN'])
      @repo = 'amfeng/reaper'

      # TODO: Add things other than Github.
    end

    def method_missing(meth, *args, &block)
      @client.send(meth, *([@repo] + args), &block)
    end
  end
end
