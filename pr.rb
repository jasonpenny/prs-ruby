#!/usr/bin/env ruby

require_relative "lib/github"

if $PROGRAM_NAME == __FILE__
  if !ENV["GITHUB_ACCESS_TOKEN"]
    puts "GITHUB_ACCESS_TOKEN environment var needs to be set to a personal access token"
    exit(1)
  end

  if ARGV.length < 1
    puts "Usage: #{__FILE__} <github pull request url>"
    exit(2)
  end

  parsed = Github.parse_pull_request_url(ARGV[0])

  pr = Github.pull_request_by_number(parsed["org"], parsed["repo"], parsed["pr_number"].to_i)
  if pr["isDraft"]
    puts "\e[7m[DRAFT]\e[0m"
  end
  Github.puts_pull_request(pr, { color: true })
end
