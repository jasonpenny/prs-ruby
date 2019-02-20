#!/usr/bin/env ruby

require_relative "lib/github"

if $PROGRAM_NAME == __FILE__
  if !ENV["GITHUB_ACCESS_TOKEN"]
    puts "GITHUB_ACCESS_TOKEN environment var needs to be set to a personal access token"
    exit(1)
  end

  if ARGV.length < 1
    puts "Usage: #{__FILE__} <team name as org/team>"
    exit(2)
  end

  org, team = ARGV[0].match(/(.+)\/(.+)/).captures

  team = Github.team_members(org, team)
  if team.nil?
    $stderr.puts "Team [#{team_name}] could not be found"
    exit(3)
  end

  puts "┌" + ("─" * 79)
  puts "│   "
  no_prs = []
  team.each_with_index do |member, i|
    prs = Github.pull_requests_for_login(member["login"]).reject { |pr| pr["owner"].downcase != org.downcase }

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
