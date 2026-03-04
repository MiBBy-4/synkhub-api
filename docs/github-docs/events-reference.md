# GitHub Events Reference

## Supported Events

SynkHub processes the following 12 GitHub webhook events:

| Event | Description | Actions | Key Payload Fields |
|-------|-------------|---------|-------------------|
| `push` | Push to a branch | *(none)* | `ref`, `commits[]`, `pusher`, `repository` |
| `pull_request` | PR opened, closed, merged, etc. | `opened`, `closed`, `reopened`, `synchronize`, `edited`, `merged` | `action`, `pull_request`, `number`, `repository` |
| `pull_request_review` | PR review submitted | `submitted`, `edited`, `dismissed` | `action`, `review`, `pull_request`, `repository` |
| `pull_request_review_comment` | Comment on PR diff | `created`, `edited`, `deleted` | `action`, `comment`, `pull_request`, `repository` |
| `issues` | Issue opened, closed, etc. | `opened`, `closed`, `reopened`, `edited`, `assigned`, `labeled` | `action`, `issue`, `repository` |
| `issue_comment` | Comment on issue or PR | `created`, `edited`, `deleted` | `action`, `comment`, `issue`, `repository` |
| `check_run` | CI check run status | `created`, `completed`, `rerequested` | `action`, `check_run`, `repository` |
| `check_suite` | CI check suite status | `completed`, `requested`, `rerequested` | `action`, `check_suite`, `repository` |
| `create` | Branch or tag created | *(none)* | `ref`, `ref_type`, `repository` |
| `delete` | Branch or tag deleted | *(none)* | `ref`, `ref_type`, `repository` |
| `release` | Release published | `published`, `created`, `edited`, `deleted` | `action`, `release`, `repository` |
| `workflow_run` | GitHub Actions run | `requested`, `completed` | `action`, `workflow_run`, `repository` |

## Event Details

### push

Triggered on any push to a repository. Does not have an `action` field.

```json
{
  "ref": "refs/heads/main",
  "before": "abc123",
  "after": "def456",
  "commits": [
    {
      "id": "def456",
      "message": "Fix bug",
      "author": { "name": "...", "email": "..." }
    }
  ],
  "pusher": { "name": "...", "email": "..." },
  "repository": { "id": 123, "full_name": "org/repo" }
}
```

### pull_request

Triggered when a PR is opened, closed, merged, or updated.

```json
{
  "action": "opened",
  "number": 42,
  "pull_request": {
    "id": 789,
    "title": "Add feature",
    "state": "open",
    "user": { "login": "..." },
    "merged": false,
    "head": { "ref": "feature-branch" },
    "base": { "ref": "main" }
  },
  "repository": { "id": 123, "full_name": "org/repo" }
}
```

### check_run / check_suite

Triggered by CI/CD status changes.

### create / delete

Triggered when a branch or tag is created or deleted. `ref_type` is either `"branch"` or `"tag"`.

### release

Triggered when a release is published or modified.

### workflow_run

Triggered when a GitHub Actions workflow is requested or completed.
