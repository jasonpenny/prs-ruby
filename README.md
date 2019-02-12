# Ruby scripts to interact with the github API


These scripts require a [personal access token](https://github.com/settings/tokens/) stored in the environment variable `GITHUB_ACCESS_TOKEN`

- generate one through the Github website
- `export GITHUB_ACCESS_TOKEN=...`

---

### View a Pull Request

`./pr.rb <github pull request url>`

This will output the title, branch, author, created time and reviews and review requests.

<img src="https://user-images.githubusercontent.com/6033/52660607-0b587d00-2ece-11e9-8912-60943cbb31bd.png" width="600" alt="Screenshot" style="max-width:100%;">

---

### Request reviews from individual members of a github team

`./request_review.rb <github pull request url> <team name>`

This will request a review from each member of a github team, so that the first review response does not remove the request from the other members.