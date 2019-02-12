require "graphql/client"
require "graphql/client/http"

module GithubGraphql
  GITHUB_ACCESS_TOKEN = ENV['GITHUB_ACCESS_TOKEN']
  URL = 'https://api.github.com/graphql'

  HttpAdapter = GraphQL::Client::HTTP.new(URL) do
    def headers(context)
      {
        "Authorization" => "Bearer #{GITHUB_ACCESS_TOKEN}",
        "User-Agent" => 'Ruby'
      }
    end
  end

  Schema = GraphQL::Client.load_schema(HttpAdapter)
  Client = GraphQL::Client.new(schema: Schema, execute: HttpAdapter)
  class QueryExecutionError < StandardError; end

  class Team
    MembersQuery = GithubGraphql::Client.parse <<-'GRAPHQL'
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

    def self.members(org, teamName)
      response = GithubGraphql::Client.query(MembersQuery, variables: { org: org, teamName: teamName })
      if response.errors.any?
        raise QueryExecutionError.new(response.errors[:data].join(", "))
      else
        response.data
      end
    end
  end

  class User
    UserProfileQuery = GithubGraphql::Client.parse <<-'GRAPHQL'
      query($username: String!) {
        user(login: $username) {
          id
          login
          name
        }
      }
    GRAPHQL
    def self.find(username)
      response = GithubGraphql::Client.query(UserProfileQuery, variables: { username: username })
      if response.errors.any?
        raise QueryExecutionError.new(response.errors[:data].join(", "))
      else
        response.data
      end
    end
  end

  class PullRequest
    PRByNumberQuery = GithubGraphql::Client.parse <<-'GRAPHQL'
    query($repoOwner: String!, $repoName: String!, $prNumber: Int!) {
      repository(owner:$repoOwner, name:$repoName) {
        pullRequest(number:$prNumber) {
          id
          url
          number
          headRefName
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

    def self.by_number(repoOwner, repoName, prNumber)
      response = GithubGraphql::Client.query(PRByNumberQuery, variables: { repoOwner: repoOwner, repoName: repoName, prNumber: prNumber })
      if response.errors.any?
        raise QueryExecutionError.new(response.errors[:data].join(", "))
      else
        response.data
      end
    end

    PRRequestReviewersMutation = GithubGraphql::Client.parse <<-'GRAPHQL'
    mutation($pullRequestId: ID!, $userIds: [ID!]) {
      requestReviews(input: { pullRequestId: $pullRequestId, userIds: $userIds, union: true }) {
        pullRequest {
          id
        },
      }
    }
    GRAPHQL

    def self.request_review(pr_id, user_ids)
      response = GithubGraphql::Client.query(PRRequestReviewersMutation, variables: { pullRequestId: pr_id, userIds: user_ids })
      if response.errors.any?
        raise QueryExecutionError.new(response.errors[:data].join(", "))
      else
        response.data
      end
    end
  end
end
