require 'net/http'
require 'uri'
require 'json'

module GithubGraphql
  GITHUB_URI = URI("https://api.github.com/graphql")
  GITHUB_ACCESS_TOKEN = ENV['GITHUB_ACCESS_TOKEN']

  def self.query(query, variables = nil)
    req = Net::HTTP::Post.new(
      GITHUB_URI,
      "Content-Type" => "application/json",
      "Authorization" => "Bearer #{GITHUB_ACCESS_TOKEN}"
    )
    if !variables.nil?
      req.body = {query: query, variables: variables}.to_json
    else
      req.body = {query: query}.to_json
    end

    res = Net::HTTP.start(
      GITHUB_URI.hostname, GITHUB_URI.port, :use_ssl => true
    ) { |http| http.request(req) }

    return JSON.parse(res.body)
  end

  def self.get_team_members(org, team_name)
    qry = <<-'GRAPHQL'
      query($org: String!, $teamName: String!) {
        organization(login:$org) {
          team(slug:$teamName) {
            members(first:100) {
              edges {
                node {
                  id
                  login
                  name
                }
              }
            }
          }
        }
      }
    GRAPHQL

    vars = {
      "org": org,
      "teamName": team_name,
    }

    return query(qry, vars)
  end

  def self.get_user_by_login(login)
    qry = <<-'GRAPHQL'
      query($login: String!) {
        user(login: $login) {
          id
          login
          name
        }
      }
    GRAPHQL

    vars = {
      "login": login
    }

    return query(qry, vars)
  end

  def self.get_my_user_login
    qry = <<-'GRAPHQL'
    query {
      viewer {
        login
      }
    }
    GRAPHQL

    return query(qry)
  end

  def self.get_pull_request_by_number(org, repo, pr_number)
    qry = <<-'GRAPHQL'
      query($repoOwner: String!, $repoName: String!, $prNumber: Int!) {
        repository(owner:$repoOwner, name:$repoName) {
          pullRequest(number:$prNumber) {
            id
            repository {
              owner {
                login
              }
            }
            url
            number
            headRefName
            mergeable
            commits(last:1){
              nodes{
                commit{
                  status{
                    state
                    contexts {
                      state
                      context
                    }
                  }
                }
              }
            }
            title
            createdAt
            author {
              ... on User {
                id
                ...userFields
              }
            }
            reviewRequests(last: 100) {
              nodes {
                requestedReviewer {
                  ... on User {
                    ...userFields
                  }
                  ... on Team {
                    name
                    login: slug
                  }
                }
              }
            }
            reviews(last: 100) {
              nodes {
                author {
                  ...userFields
                }
                state
              }
            }
          }
        }
      }

      fragment userFields on User {
        name
        login
      }
    GRAPHQL

    vars = {
      repoOwner: org,
      repoName: repo,
      prNumber: pr_number,
    }

    return query(qry, vars)
  end

  def self.get_pull_requests_for_login(login)
    qry = <<-'GRAPHQL'
      query($queryString: String!) {
        search(query:$queryString, type: ISSUE, first: 100) {

          edges {
            node {
              ... on PullRequest {
                id
                repository {
                  owner {
                    login
                  }
                }
                url
                number
                headRefName
                mergeable
                commits(last:1){
                  nodes{
                    commit{
                      status{
                        state
                        contexts {
                          state
                          context
                        }
                      }
                    }
                  }
                }
                title
                createdAt
                author {
                  ... on User {
                    id
                    ...userFields
                  }
                }
                reviewRequests(last: 100) {
                  nodes {
                    requestedReviewer {
                      ... on User {
                        ...userFields
                      }
                      ... on Team {
                        name
                        login: slug
                      }
                    }
                  }
                }
                reviews(last: 100) {
                  nodes {
                    author {
                      ...userFields
                    }
                    state
                  }
                }
              }
            }
          }
        }
      }

      fragment userFields on User {
        name
        login
      }
    GRAPHQL

    vars = {
      queryString: "is:open is:pr author:#{login}"
    }

    return query(qry, vars)
  end

  def self.request_review_on_pull_request(pr_id, user_ids)
    qry = <<-'GRAPHQL'
      mutation($pullRequestId: ID!, $userIds: [ID!]) {
        requestReviews(input: { pullRequestId: $pullRequestId, userIds: $userIds, union: true }) {
          pullRequest {
            id
          },
        }
      }
    GRAPHQL

    vars = {
      pullRequestId: pr_id,
      userIds: user_ids
    }

    return query(qry, vars)
  end
end
