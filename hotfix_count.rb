#!/usr/bin/env ruby

require_relative "lib/github"

if $PROGRAM_NAME == __FILE__
  if !ENV["GITHUB_ACCESS_TOKEN"]
    puts "GITHUB_ACCESS_TOKEN environment var needs to be set to a personal access token"
    exit(1)
  end

  if ARGV.length != 2
    puts "Usage: #{__FILE__} <repo> <release number>"
    exit(1)
  end

  COUNT_TO_SHOW = 20
  n = ARGV[1].to_i
  s = "Hotfix counts for the release-#{n} - release-#{n - COUNT_TO_SHOW}"
  puts s
  puts "-" * s.length
  n.downto(n - COUNT_TO_SHOW) do |release|
    prs = Github.all_pull_request_ids_for_repo(ARGV[0], "base:release-#{release}")
    puts "release-#{release.to_s.ljust(3)}: #{prs.length.to_s.rjust(3)}"
  end
end
