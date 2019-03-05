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
    extra_filters = ARGV[1]
  else
    extra_filters = ""
  end

  parsed_team = Github.parse_org_and_team(team_name)

  team = Github.team_members(parsed_team["org"], parsed_team["team_name"])
  if team.nil?
    $stderr.puts "Team [#{team_name}] could not be found"
    exit(3)
  end

  puts "┌" + ("─" * 79)
  puts "│   "
  no_prs = []
  team.each_with_index do |member, i|
    prs = Github.pull_requests_for_login(member["login"], extra_filters).reject { |pr| pr["owner"].downcase != parsed_team["org"].downcase }

    if !prs.empty?
      Github.puts_multiple_pull_requests(prs, { prefix: "│   " })
    else
      no_prs << member
    end

    if !prs.empty? && i < team.size - 1
      puts "│   "
      puts "├" + ("─" * 79)
      puts "│   "
    end
  end

  no_prs.each_with_index do |member, i|
      puts "│   " + Github.name_and_login(member)
      puts "│   " + "No open PRs"

      if i < no_prs.size - 1
        puts "│   "
      end
  end
  puts "│   "
  puts "└" + ("─" * 79)
end
