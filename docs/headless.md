# Headless: personas outside the terminal

An output style is not limited to your interactive session. `claude -p` takes
`--settings` as inline JSON, so any style can be applied to a one-shot invocation
and dropped into a hook, a script, or CI.

```bash
claude -p "why is this test flaky?" --settings '{"outputStyle":"Beatrice"}'
```

> [!IMPORTANT]
> The value is the style's **display name** — the `name:` field in its frontmatter
> — not the filename. `Imouto-nya`, not `imouto-nya.md`.

Verified output from exactly that command:

```
Obviously.

It is the list of values React compares against the previous render — Betty has
answered this exact question more times than the archive has shelves, kashira —
and the effect re-runs only when one of them has changed; omit it and the effect
fires every render, give it `[]` and it fires once, na no yo.
```

## Recipes

### A one-shot alias

```bash
# ~/.bashrc or ~/.zshrc
dere() { claude -p "$*" --settings '{"outputStyle":"Tsundere"}'; }
```

```
$ dere "what does Object.is do differently from ==="
```

### Pre-push review

Gets a read on your diff before it leaves the machine. Advisory only — it prints
and always exits 0, because a persona should never be able to block your push.

```bash
#!/usr/bin/env bash
# .git/hooks/pre-push   (chmod +x)
range="origin/$(git branch --show-current)..HEAD"
git rev-parse --verify --quiet "origin/$(git branch --show-current)" >/dev/null || range="HEAD~1..HEAD"
diff=$(git diff "$range" -- . ':(exclude)*.lock' ':(exclude)*.svg' | head -c 40000)
[ -z "$diff" ] && exit 0

printf '%s' "$diff" | claude -p \
  "Review this diff. Note anything that would break, and say so plainly. Be brief." \
  --settings '{"outputStyle":"Tsundere"}'
exit 0
```

### GitHub Actions PR review

```yaml
name: dere-review
on: pull_request

jobs:
  review:
    runs-on: ubuntu-latest
    permissions: { pull-requests: write, contents: read }
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }
      - run: npm install -g @anthropic-ai/claude-code
      - id: review
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          curl -fsSL https://raw.githubusercontent.com/Luscha/claude-dere/main/install.sh | bash
          git diff origin/${{ github.base_ref }}...HEAD | head -c 40000 > /tmp/diff
          claude -p "Review this diff. Flag anything that would break. Be brief." \
            --settings '{"outputStyle":"Beatrice"}' < /tmp/diff > /tmp/review.md
      - uses: actions/github-script@v7
        with:
          script: |
            const body = require('fs').readFileSync('/tmp/review.md', 'utf8')
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner, repo: context.repo.repo,
              body,
            })
```

## Two things worth knowing before you wire this up

**Cost.** Interactive Claude Code draws on your subscription. A CI job does not —
it needs `ANTHROPIC_API_KEY` and bills per token against API credits. A review bot
firing on every push to every PR is a real line item. Scope it: only on
`opened`/`ready_for_review`, or only on paths that matter.

**The rails still hold, and that is the point.** These styles keep filenames, line
numbers and error text exact, and drop the voice entirely when something genuinely
matters. A persona reviewing your PR is a joke that does not cost you the review.
