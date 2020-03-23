#!/usr/bin/env ruby

require_relative "lib/github"

if $PROGRAM_NAME == __FILE__
  if !ENV["GITHUB_ACCESS_TOKEN"]
    puts "GITHUB_ACCESS_TOKEN environment var needs to be set to a personal access token"
    exit(1)
  end

  if ARGV.length < 1 && !ENV["GITHUB_TEAM"]
    puts "Usage: #{__FILE__} <team name as org/team> <optional extra filters>"
    exit(2)
  end

  if ARGV.length > 0
    team_name = ARGV[0]
  else
    team_name = ENV["GITHUB_TEAM"]
  end

  if ARGV.length > 1
    skip_team_members = ARGV[1].split(',')
  else
    skip_team_members = []
  end

  if ARGV.length > 2
    skip_pr_ids = ARGV[2].split(',')
  else
    skip_pr_ids = []
  end

  parsed_team = Github.parse_org_and_team(team_name)

  team = Github.team_members(parsed_team["org"], parsed_team["team_name"])
  if team.nil?
    $stderr.puts "Team [#{team_name}] could not be found"
    exit(3)
  end

  puts "┌" + ("─" * 79)
  puts "│   "
  all_prs = {}

  team.each_with_index do |member, i|
    next if skip_team_members.include?(member["login"])
    prs = Github.open_pull_requests_for_involves(member["login"]).reject { |pr| pr["owner"].downcase != parsed_team["org"].downcase }

    for pr in prs
      next if skip_pr_ids.include?(pr["url"])
      all_prs[pr["url"]] = pr
    end
  end

  prs = Github.open_pull_requests_for_team(team_name)

  for pr in prs
    next if skip_pr_ids.include?(pr["url"])
    all_prs[pr["url"]] = pr
  end

  Github.puts_multiple_pull_requests(all_prs.values, { prefix: "│   " })
  puts "│   "
  puts "└" + ("─" * 79)
end
