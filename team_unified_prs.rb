#!/usr/bin/env ruby

require_relative "lib/github"

def positional_arg_or_env(idx, env_var)
  if ARGV.length > idx
    return ARGV[idx]
  else
    return (ENV[env_var] || "")
  end
end

def positional_arg_or_env_split(idx, env_var)
  return positional_arg_or_env(idx, env_var).split(',')
end

if $PROGRAM_NAME == __FILE__
  if !ENV["GITHUB_ACCESS_TOKEN"]
    puts "GITHUB_ACCESS_TOKEN environment var needs to be set to a personal access token"
    exit(1)
  end

  if ARGV.length < 1 && !ENV["GITHUB_TEAM"]
    puts "Usage: #{__FILE__} <team name as org/team> <optional extra filters>"
    exit(2)
  end

  team_name = positional_arg_or_env(0, "GITHUB_TEAM")
  skip_team_members = positional_arg_or_env_split(1, "GITHUB_SKIP_TEAM_MEMBERS")
  skip_pr_ids = positional_arg_or_env_split(2, "GITHUB_SKIP_PR_IDS")
  team_repos = positional_arg_or_env_split(3, "GITHUB_TEAM_REPOS")

  parsed_team = Github.parse_org_and_team(team_name)

  team = Github.team_members(parsed_team["org"], parsed_team["team_name"])
  if team.nil?
    $stderr.puts "Team [#{team_name}] could not be found"
    exit(3)
  end

  all_prs = {}

  add_prs = proc do |prs|
    for pr in prs
      next if skip_pr_ids.include?(pr["url"]) || pr["archived"]
      all_prs[pr["url"]] = pr
    end
  end

  team.each do |member|
    next if skip_team_members.include?(member["login"])
    add_prs.call(
      Github.open_pull_requests_for_involves(member["login"]).reject do |pr|
        pr["owner"].downcase != parsed_team["org"].downcase
      end
    )
  end

  add_prs.call(Github.open_pull_requests_for_team(team_name))

  team_repos.each do |repo|
    add_prs.call(Github.open_pull_requests_for_repo(repo))
  end

  prs_reverse_date = all_prs.values.sort{|a,b| b["createdAt"] <=> a["createdAt"]}
  Github.puts_multiple_pull_requests(prs_reverse_date, { indexed: true })
end
