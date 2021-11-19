#!/usr/bin/env ruby

require_relative "lib/github"

if $PROGRAM_NAME == __FILE__
  if !ENV["GITHUB_ACCESS_TOKEN"]
    puts "GITHUB_ACCESS_TOKEN environment var needs to be set to a personal access token"
    exit(1)
  end

  if ARGV.length != 2
    puts "Usage: #{__FILE__} <repo> <date>"
    exit(1)
  end

  prs = Github.open_pull_requests_for_repo(ARGV[0], "updated:<#{ARGV[1]}")
  counts = Hash.new(0)
  prs.each do |pr|
    key = [pr["author"], pr["authorLogin"]]
    counts[key] += 1
  end

  counts
    .sort_by { |key, val| [-val, key] }
    .each do |(user, login), count|
    puts "#{count.to_s.rjust(2)} #{user.ljust(42)} https://github.com/#{ARGV[0]}/pulls?q=is%3Aopen+is%3Apr+author%3A#{login}+updated%3A%3C#{ARGV[1]}"
    end
end
