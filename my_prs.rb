#!/usr/bin/env ruby

require_relative "lib/github"

if $PROGRAM_NAME == __FILE__
  if !ENV["GITHUB_ACCESS_TOKEN"]
    puts "GITHUB_ACCESS_TOKEN environment var needs to be set to a personal access token"
    exit(1)
  end

  login = Github.my_user_login()

  prs = Github.pull_requests_for_login(login)
  Github.puts_multiple_pull_requests(prs)
end
