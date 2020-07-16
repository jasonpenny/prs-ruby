# Ruby scripts to interact with the github API


These scripts require a [personal access token](https://github.com/settings/tokens/) stored in the environment variable `GITHUB_ACCESS_TOKEN`

- generate one through the Github website
- `export GITHUB_ACCESS_TOKEN=...`
- optionally set `GITHUB_TEAM` to avoid having to pass it as a param to the scripts
`export GITHUB_TEAM=org/team`

---

### View a Pull Request

`./pr.rb <github pull request url>`

This will output the title, branch, author, created time and reviews and review requests.

<img src="https://user-images.githubusercontent.com/6033/52660607-0b587d00-2ece-11e9-8912-60943cbb31bd.png" width="600" alt="Screenshot" style="max-width:100%;">

---

### View my open Pull Requests

`./my_prs.rb`

This will output all open PRs for the user that owns the GITHUB\_ACCESS\_TOKEN.

---

### View open Pull Requests for all members of a github team

```sh
./team_prs.rb <org/team>

# or
export GITHUB_TEAM=<org/team>
./team_prs.rb
```

This will output all open PRs for members of the team, for repos that are in the `org`

---

### View all Pull Requests involving any members of a github team

```sh
./team_unified_prs.rb <org/team> <team members to skip> <pr ids to skip> <team repos to include>

# or
export GITHUB_TEAM=<org/team>
./team_unified_prs.rb
```

This will output all PRs opened by, commented on, requested reviews on, etc for any members of the team on any repos that are in the `org`, or for any PRs that are opened by anyone on repos that are listed as "owned" by the team.

Additionally you can skip team member PRs using the 2nd arg or env var `GITHUB_SKIP_TEAM_MEMBERS` or skip specific PRs using the 3rd arg or env var `GITHUB_SKIP_PR_IDS` and you can list the team repos to include with the 4th arg or env var `GITHUB_TEAM_REPOS`, both are comma separated lists.

---

### Request reviews from individual members of a github team

```sh
./request_review.rb <github pull request url> <team name>

# or
export GITHUB_TEAM=<org/team>
./request_review.rb <github pull request url>
```

This will request a review from each member of a github team, so that the first review response does not remove the request from the other members.
