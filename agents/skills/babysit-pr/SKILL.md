---
name: babysit-pr
description: >
  Use when asked to watch, monitor, or babysit an open pull request: follow CI and reviews until it is ready to
  merge, fix failures the branch caused, retry flaky runs, and stop when a human decision is needed.
---

# PR babysitter

Watch a PR until one of these happens:

- it is merged or closed;
- it is ready: required checks green, no unresolved review threads, no conflicts, not a draft;
- something needs the owner.

The repository's own rules (`AGENTS.md`, `CLAUDE.md`, contributing docs) override this skill, especially about
when you may push or merge. Never merge unless the owner asked you to.

## Start

1. Check that `gh` is authenticated (`gh auth status`) and resolve the PR: the one given, or the PR for the
   current branch.
2. Tell the owner which PR you are tracking, with its link.
3. Before you edit anything, make sure `HEAD` is the PR's head branch at its head SHA. If you are on another
   branch, check the PR out in its own worktree.
4. Find the local gate: the build/test/lint command the repository's docs name. Run it before every push.

## The loop

If your harness has a PR-watch or wait tool, use it. Otherwise poll `gh pr view` and `gh pr checks` with a pause
of a minute or more between polls. Don't burn tokens on tight loops, and don't stop polling just because a check
is still pending. Cap a session at roughly 90 minutes, then report where things stand.

On each change, act on what you see:

| State | Do |
|---|---|
| Checks running, bot review in progress | Wait. Don't push. |
| Check failed | Read the logs and classify it (below). |
| New review comments | Triage them (below). |
| Conflicts, or behind a base that requires up-to-date branches | Update the branch (below). |
| Check pending far longer than usual (~30 min) | Inspect the run, report it as hung. |
| No checks at all, a required check never ran, or a check skipped unexpectedly | Find out why (path filters, disabled workflow, fork approval, missing trigger). Tell the owner. A PR without checks is never "ready". |
| All green but GitHub says `BLOCKED` | Look at branch protection and rulesets, tell the owner what blocks it. Never bypass. |
| Green but draft | Ask the owner to mark it ready. |
| Ready | Report and stop. Mention any review bot that never reviewed the head commit. |
| Merged or closed | Clean up (below) and stop. |

### CI failures

- **Branch-caused** (fails on code this PR touches, reproduces locally, base is green): fix it.
- **Flaky or infra** (timeouts, network, runner errors, known-flaky e2e suites, passes on rerun): rerun the failed
  jobs with `gh run rerun --failed`. At most three reruns per head SHA, then hand it to the owner.
- **Pre-existing** (also fails on the base branch): don't fix it here. Tell the owner.

### Review bots

Bots (Codex, Copilot, PR-specific review workflows) often signal "reviewing" with a reaction or a running check
and post findings when done. Don't push or merge while one is mid-review. Their status or summary comments
("no major issues found") are results, not findings. A bot that hasn't reviewed the head after a reasonable wait
(~10 min after checks finish) shouldn't block forever; note it in your report.

## Triage every finding before fixing it

Applies to bot and human comments alike. A true finding is not automatically a fix for this PR:

| | Blocker | Improvement |
|---|---|---|
| **In scope** | Fix now. | Fix now if trivial, otherwise file an issue. |
| **Out of scope** | File an issue, and say so on the PR. | File an issue. |

In scope means it concerns the behaviour this PR set out to change. Ask: would this defect exist on the base
without my change? If yes, it's pre-existing and belongs in an issue. A blocker means visible harm, data loss, or
a security hole. Hardening, stricter validation, and "this could also be wrong if" are improvements, however
confidently a bot says otherwise. A fix that would break something that works today is the owner's call.

Reply on each thread with what you did (fixed, issue link, or why not) and resolve it. No bot thread stays open at
merge time.

Stop the review loop and ask the owner when:

- three rounds in a row produce no in-scope blocker;
- findings start targeting code that only exists because of earlier findings;
- the diff has grown well past the task (check `git diff --stat` against the base, not memory);
- every push produces new findings, so the PR can never go clean.

Bring numbers (commits, files, diff size) and propose a split. Before reverting out-of-scope work, park it on a
`followup/<topic>` branch and say so.

## Push discipline

Every push restarts bot reviews, so push once per fix cycle, when:

1. every known issue is fixed locally (CI logs, bot findings, human comments);
2. no review bot is mid-review, so its findings land in the same batch;
3. the local gate is green.

Start fixing as soon as you've diagnosed something; only the push waits.

## Updating the branch

1. Wait until no review bot is running.
2. Get the real base from `gh pr view --json baseRefName`; never assume `main`. Fetch it from the repository the
   PR targets (for a fork, that is not `origin`).
3. Merge the base into the PR branch, resolve conflicts, fold in pending review fixes, run the local gate, push.

Rebase only if the owner asks; then push with `--force-with-lease`, never a plain force push. Afterwards, confirm
your earlier fixes survived.

## Post-merge cleanup

A closed PR is not necessarily merged. Clean up only if `gh pr view --json mergedAt` shows a merge date. For a PR
closed without merging, keep everything and tell the owner.

Run every step from the main checkout, never from inside the PR's worktree. Skip any step whose worktree or branch
doesn't exist. Clean up local state only; never delete remote branches.

1. If `git worktree list` shows the PR branch in a linked worktree, `git worktree remove <path>`. If Git refuses
   because of uncommitted changes, don't force it; tell the owner. Remove the worktree before the branch, since Git
   won't delete a branch a worktree still uses.
2. Delete the local branch only when nothing would be lost. Squash merges make the branch look unmerged, so
   `git branch -d` refuses and `-D` is needed. Before force-deleting, prove the local tip equals the merged head:
   compare `git rev-parse <branch>` with `gh pr view --json headRefOid`. If they differ, the branch has unmerged
   commits: keep it and tell the owner.
3. Update the base branch in the main checkout with `git pull --ff-only`.
