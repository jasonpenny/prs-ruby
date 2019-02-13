#!/usr/bin/env ruby

require_relative "lib/github"

if $PROGRAM_NAME == __FILE__
  if !ENV["GITHUB_ACCESS_TOKEN"]
    puts "GITHUB_ACCESS_TOKEN environment var needs to be set to a personal access token"
    exit(1)
  end

  login = Github.my_user_login()

  prs = Github.pull_requests_for_login(login)
  prs.each_with_index do |pr, i|
    puts pr["url"]
    Github.puts_pull_request(pr)

    if i < prs.size - 1
      puts ""
      puts "-" * 80
      puts ""
    end
  end
end
