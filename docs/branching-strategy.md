# Branching strategy

Buggy uses GitHub Flow. `main` is the shared integration branch. Start each change from the latest `main` and merge it back through a pull request. Keep branches focused and short-lived. Work on different services can proceed on separate branches and merge independently.

## Branch names

Use lowercase names in the form `<type>/<short-description>`, with hyphens between words. Include the service name when it helps identify the change.

| Type | Example |
| --- | --- |
| Feature | `feat/order-delivery-status` |
| Bug fix | `fix/payment-webhook-retry` |
| Documentation | `docs/branching-strategy` |
| Maintenance | `chore/update-build-tooling` |

## Pull request workflow

1. Once `main` has its first commit on `origin`, run `git switch main` and `git pull --ff-only origin main` to update your local copy.
2. Create a branch with `git switch -c <branch-name>`. Commit your changes and publish it with `git push -u origin <branch-name>`.
3. Open a pull request targeting `main`. Describe the change, how you verified it, and any API or event changes that affect other services.
4. Address review feedback, resolve conflicts, and make sure any required checks pass. Squash and merge the pull request, then delete the merged branch.

Urgent fixes follow the same workflow from `main`. If a merged change needs to be undone, open a pull request that reverts it.

## Enable the push guard

Run `git config --local core.hooksPath .githooks` once in each clone. On macOS and Linux, make sure `.githooks/pre-push` is executable. The hook blocks pushes targeting `main` or `master`, including force pushes and deletions. It checks the remote destination, so pushing a differently named local branch to either protected branch is also blocked.

Use GitHub branch protection to enforce this policy across clones. If the remote is empty, initialize `main` before enforcing pull-request-only updates on GitHub.
