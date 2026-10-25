# githubgreen

`githubgreen` is a small repo whose only job is to keep your GitHub contribution graph green.

It works in two layers:

1. A GitHub Actions workflow makes a few small commits on five randomly selected days each week.
2. A local backfill script can fill older dates so the last 365 days are not mostly blank.

## How it works

The workflow appends a tiny JSON line to `data/green-log.jsonl` and pushes the change to your default branch. GitHub counts those commits on your profile as long as:

- the repo is not a fork
- the commits land on the default branch
- the commit email is connected to your GitHub account

## Setup

1. Create a standalone GitHub repository named `githubgreen`.
2. Push this folder to its default branch, usually `main`.
3. In the GitHub repo, open `Settings -> Actions -> General`.
4. Set `Workflow permissions` to `Read and write permissions`.
5. In `Settings -> Secrets and variables -> Actions -> Variables`, add:
   - `GH_GREEN_EMAIL`: a verified email that belongs to your GitHub account
   - `GH_GREEN_NAME`: optional display name for the commits
6. Open the `Actions` tab and manually run `Keep Graph Green` once.

If you keep the repo private, enable private contributions on your GitHub profile if you want the tiles to show up there.

## Weekly automation

The scheduled workflow lives at `.github/workflows/keep-green.yml`.

By default it:

- checks every day in the `Asia/Kolkata` time zone
- selects exactly five days per Monday-Sunday week, including possible weekends, and skips the other two
- uses the week's Monday date as a random seed so retries and manual runs keep the same selection
- makes a random `1` to `4` commits on each selected day, dated within that India calendar day
- changes a real tracked file so the commits are not empty

Manual runs also respect the two days off. The five-day target depends on the workflow running successfully on each selected day; missed runs are not backfilled. Existing history is unchanged, so a week already in progress may still contain commits from the old daily schedule.

To check the weekly selection and date boundaries locally:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\test-green-schedule.ps1
```

## Backfill old days

If you want the last year to look green instead of waiting for future days, run this once from a real git repo:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\backfill-green.ps1 -Days 365 -MinCommitsPerDay 1 -MaxCommitsPerDay 3
git push
```

That script writes dated commits across past days using the Git author and commit dates.

## Notes

- GitHub may take up to 24 hours to show contributions on your graph.
- Scheduled workflows only run from the default branch.
- Inactive public repos can have scheduled workflows disabled by GitHub. If that happens, re-enable the workflow from the `Actions` tab.
