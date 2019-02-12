#!/usr/bin/env ruby

require_relative "lib/github"

if $PROGRAM_NAME == __FILE__
  if !ENV["GITHUB_ACCESS_TOKEN"]
    puts "GITHUB_ACCESS_TOKEN environment var needs to be set to a personal access token"
    exit(1)
  end

  if ARGV.length < 2
    puts "Usage: #{__FILE__} <github pull request url> <team name>"
    exit(2)
  end

  parsed = Github.parse_pull_request_url(ARGV[0])
  team_name = ARGV[1]

  pr = Github.pull_request_by_number(parsed["org"], parsed["repo"], parsed["pr_number"].to_i)

  team = Github.team_members(parsed["org"], team_name)
  if team.nil?
    $stderr.puts "Team [#{team_name}] could not be found"
    exit(3)
  end

  other_member_ids = team.reject { |member| member["id"] == pr["authorId"] }.map { |tm| tm["id"] }

  Github.request_review_on_pull_request(pr["id"], other_member_ids)

  puts "Requested reviews"
end
