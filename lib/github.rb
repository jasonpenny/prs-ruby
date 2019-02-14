require_relative "github-graphql"

module Github
  def self.pull_request_by_number(org, repo, pr_number)
    data = GithubGraphql.get_pull_request_by_number(org, repo, pr_number)
    return _pr_data(data["data"]["repository"]["pullRequest"])
  end

  def self.pull_requests_for_login(login)
    data = GithubGraphql.get_pull_requests_for_login(login)
    return data["data"]["search"]["edges"].map do |edge|
      _pr_data(edge["node"])
    end
  end

  def self._pr_data(pr)
    result = pr.select do |k, v|
      %w(id url number headRefName title createdAt).include? k
    end
    result["authorId"] = pr["author"]["id"]
    result["authorLogin"] = pr["author"]["login"]
    result["authorName"] = pr["author"]["name"]
    result["author"] = name_and_login(pr["author"])

    result["reviews"] = pr["reviews"]["nodes"].inject({}) do |reviews, review|
      reviews.merge({ name_and_login(review["author"]) => review["state"] })
    end

    result["reviewRequests"] = pr["reviewRequests"]["nodes"].map do |rr|
      { "user" => name_and_login(rr["requestedReviewer"]) }
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
    return nil if team["data"]["organization"]["team"].nil?

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

  def self.puts_pull_request(pr)
    puts "\e[1m#{pr["title"]}\e[0m #{pr["headRefName"]}"
    puts "#{pr["author"]} #{pr["createdAt"]}"

    if !pr["canMerge"]
      puts " \e[91m\e[1m✘  Merge Conflict\e[0m"
    end

    if !pr["checkFailures"].nil?
      puts " \e[91m\e[1m✘  Failed checks:\e[0m #{pr["checkFailures"].join(", ")}"
    end

    puts ""

    pr["reviews"].each do |user, state|
      if state == "APPROVED"
        puts " \e[92m\e[1m✔ \e[0m #{user}"
      elsif state == "CHANGES_REQUESTED"
        puts " \e[91m\e[1m±\e[0m  #{user}"
      elsif state == "COMMENTED"
        puts "💬  #{user}"
      end
    end

    pr["reviewRequests"].each do |rr|
      puts " \e[33m\e[1m●\e[0m  #{rr["user"]}"
    end
  end

  def self.parse_pull_request_url(url)
    keys = ["org", "repo", "pr_number"]
    vals = url.match(/https:\/\/github.com\/(.+)\/(.+)\/pull\/(.+)/).captures

    return Hash[keys.zip(vals)]
  end

  def self.name_and_login(obj)
    if obj["name"] && !obj["name"].empty?
      "#{obj["name"]} (@#{obj["login"]})"
    else
      "@#{obj["login"]}"
    end
  end
end
