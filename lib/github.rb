require "date"
require 'active_support/core_ext/date_time'
require_relative "github-graphql"

module Github
  def self.pull_request_by_number(org, repo, pr_number)
    data = GithubGraphql.get_pull_request_by_number(org, repo, pr_number)
    return _pr_data(data["data"]["repository"]["pullRequest"])
  end

  def self.open_pull_requests_for_author(login, extra_filters="")
    data = GithubGraphql.get_open_pull_requests_for_author(login, extra_filters)
    return _map_pr_data_search(data)
  end

  def self.open_pull_requests_for_involves(login, extra_filters="")
    data = GithubGraphql.get_open_pull_requests_for_involves(login, extra_filters)
    return _map_pr_data_search(data)
  end

  def self.open_pull_requests_for_team(team, extra_filters="")
    data = GithubGraphql.get_open_pull_requests_for_team(team, extra_filters)
    return _map_pr_data_search(data)
  end

  def self.open_pull_requests_for_repo(repo, extra_filters="")
    data = GithubGraphql.get_open_pull_requests_for_repo(repo, extra_filters)
    return _map_pr_data_search(data)
  end

  def self.all_pull_request_ids_for_repo(repo, extra_filters="")
    data = GithubGraphql.get_any_pull_request_ids_for_repo("repo:#{repo} #{extra_filters}")
    return data["data"]["search"]["edges"]
  end

  def self._map_pr_data_search(data)
    return data["data"]["search"]["edges"].map do |edge|
      _pr_data(edge["node"]) unless edge.nil?
    end
  end

  def self._pr_data(pr)
    result = pr.select do |k, v|
      %w(id url number headRefName baseRefName title createdAt isDraft).include? k
    end
    result["owner"] = pr["repository"]["owner"]["login"]
    result["repoArchived"] = pr["repository"]["isArchived"]
    result["authorId"] = pr["author"]["id"]
    result["authorLogin"] = pr["author"]["login"]
    result["authorName"] = pr["author"]["name"]
    result["author"] = name_and_login(pr["author"])

    result["reviews"] = pr["reviews"]["nodes"].inject({}) do |reviews, review|
      key = name_and_login(review["author"])
      if reviews[key] && review["state"] == "COMMENTED"
        # if reviewer APPROVED and then COMMENTED, keep as APPROVED
        reviews
      else
        reviews.merge({ key => review["state"] })
      end
    end

    timeline_events = (pr["timelineItems"] && pr["timelineItems"]["nodes"]) || []
    result["reviewRequests"] = pr["reviewRequests"]["nodes"].map do |rr|
      if !rr["requestedReviewer"].nil?
        login = rr["requestedReviewer"]["login"]
        matching = timeline_events.select do |evt|
          evt && evt["requestedReviewer"] && evt["requestedReviewer"]["login"] == login
        end
        created_at = matching.map { |e| e["createdAt"] }.max
        { "user" => name_and_login(rr["requestedReviewer"]), "createdAt" => created_at }
      end
    end

    result["canMerge"] = pr["mergeable"] != "CONFLICTING"

    status = pr["commits"]["nodes"][0]["commit"]["status"]
    if (!status.nil?) && status["state"] == "FAILURE"
      result["checkFailures"] = status["contexts"].reject { |c| c["state"] == "SUCCESS" }.map { |c| c["context"] }
    end

    return result
  end

  ## Returns a list of members {id, login, name}
  def self.team_members(org, team_name)
    team = GithubGraphql.get_team_members(org, team_name)
    return nil if team["data"]["organization"].nil? || team["data"]["organization"]["team"].nil?

    return team["data"]["organization"]["team"]["members"]["edges"].map { |edge| edge["node"] }
  end

  def self.user_by_login(login)
    data = GithubGraphql.get_user_by_login(login)
    return data["data"]["user"]
  end

  def self.my_user_login
    data = GithubGraphql.get_my_user_login()
    return data["data"]["viewer"]["login"]
  end

  def self.request_review_on_pull_request(pr_id, user_ids)
    GithubGraphql.request_review_on_pull_request(pr_id, user_ids)
  end

  def self.puts_multiple_pull_requests(prs, options = {})
    prs.each_with_index do |pr, i|
      if STDOUT.isatty
        url = "\e[36m#{pr["url"]}\e[0m"
        if pr["isDraft"]
          url = "\e[7m[DRAFT]\e[0m #{url}"
        end
      else
        url = pr["url"]
        if pr["isDraft"]
          url = "[DRAFT] #{url}"
        end
      end
      url = (i + 1).to_s + ". " + url if options[:indexed]
      puts options[:prefix].nil? ? url : options[:prefix] + url
      puts_pull_request(pr, options)

      if i < prs.size - 1
        puts options[:prefix]
        puts options[:prefix]
      end
    end
  end

  def self.puts_pull_request(pr, options = {})
    puts_with_prefix = proc do |prefix, s|
      puts prefix.nil? ? s : prefix + s
    end.curry.call(options[:prefix])

    color = STDOUT.isatty

    ref = pr["headRefName"]
    if !["master", "develop"].include? pr["baseRefName"]
      ref = "#{pr["baseRefName"]}..#{ref}"
    end
    if color
      puts_with_prefix.call "\e[1m#{pr["title"]}\e[0m #{ref}"
    else
      puts_with_prefix.call "#{pr["title"]} #{ref}"
    end
    formatted_created_at = DateTime.parse(pr["createdAt"])
      .localtime
      .strftime("%Y-%m-%d %I:%M %p")
    puts_with_prefix.call "#{pr["author"]} #{relative_time(pr["createdAt"])} (#{formatted_created_at})"

    if !pr["canMerge"]
      if color
        puts_with_prefix.call " \e[91m\e[1m✘  Merge Conflict\e[0m"
      else
        puts_with_prefix.call " ✘  Merge Conflict"
      end
    end

    if !pr["checkFailures"].nil?
      if color
        puts_with_prefix.call " \e[91m\e[1m✘  Failed checks:\e[0m #{pr["checkFailures"].join(", ")}"
      else
        puts_with_prefix.call " ✘  Failed checks: #{pr["checkFailures"].join(", ")}"
      end
    end

    if (!pr["reviews"].empty?) || (!pr["reviewRequests"].empty?)
      puts_with_prefix.call ""
    end

    pr["reviews"].each do |user, state|
      if state == "APPROVED"
        if color
          puts_with_prefix.call " \e[92m\e[1m✔ \e[0m #{user}"
        else
          puts_with_prefix.call " ✔  #{user}"
        end
      elsif state == "CHANGES_REQUESTED"
        if color
          puts_with_prefix.call " \e[91m\e[1m±\e[0m  #{user}"
        else
          puts_with_prefix.call " ±  #{user}"
        end
      elsif state == "COMMENTED"
        puts_with_prefix.call "💬  #{user}"
      end
    end

    user_width = pr["reviewRequests"].compact.map { |rr| rr["user"].length }.max || 0

    pr["reviewRequests"].each do |rr|
      next if rr.nil?

      time_info = ""
      if rr["createdAt"]
        formatted = DateTime.parse(rr["createdAt"])
          .localtime
          .strftime("%Y-%m-%d %I:%M %p")
        time_info = "  #{relative_time_hm(rr["createdAt"])} (#{formatted})"
      end

      user_padded = rr["user"].ljust(user_width)

      if color
        puts_with_prefix.call " \e[33m\e[1m●\e[0m  #{user_padded}#{time_info}"
      else
        puts_with_prefix.call " ●  #{user_padded}#{time_info}"
      end
    end
  end

  def self.parse_pull_request_url(url)
    keys = ["org", "repo", "pr_number"]
    vals = url.match(/https:\/\/github.com\/(.+)\/(.+)\/pull\/(.+)/).captures

    return Hash[keys.zip(vals)]
  end

  def self.parse_org_and_team(team)
    keys = ["org", "team_name"]
    m = team.match(/(.+)\/(.+)/)
    items = m ? m.captures : ["", team]

    return Hash[keys.zip(items)]
  end

  def self.name_and_login(obj)
    if obj["name"] && !obj["name"].empty?
      "#{obj["name"]} (@#{obj["login"]})"
    else
      "@#{obj["login"]}"
    end
  end

  def self.relative_time(dtStr)
    diff = DateTime.now - DateTime.parse(dtStr)
    if diff > 30.5
      return time_ago(diff / 30.5, "month")
    elsif diff > 1.0
      return time_ago(diff, "day")
    end

    diff *= 24.0
    if diff > 1.5
      return time_ago(diff, "hour")
    end

    diff *= 60
    if diff > 1.0
      return time_ago(diff, "minute")
    end

    diff *= 60
    return time_ago(diff, "second")
  end

  def self.relative_time_hm(dtStr)
    total_minutes = ((DateTime.now.to_time - DateTime.parse(dtStr).to_time) / 60).to_i
    total_minutes = 0 if total_minutes < 0
    days = total_minutes / (60 * 24)
    hours = (total_minutes / 60) % 24
    minutes = total_minutes % 60
    days_str = days > 0 ? format("%2dd", days) : "   "
    format("%s%02dh%02dm ago", days_str, hours, minutes)
  end

  def self.time_ago(diff, period)
    df = diff.floor
    if df != 1
      period = period + "s"
    end

    return "#{df} #{period} ago"
  end
end
