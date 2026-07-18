#!/usr/bin/env bash
# Weekly upstream digest for the Dupacode fork: summarizes supabitapp/supacode
# commits not yet merged here and flags ones touching files this fork modifies.
# State lives in the previous digest issue (digest-marker comment), so the job
# needs no external storage; first run falls back to the merge-base.
set -euo pipefail

repo="${GITHUB_REPOSITORY:?}"
upstream_sha=$(git rev-parse upstream/main)

# Files this fork changes; upstream commits touching them are merge-conflict risks.
fork_files='Project.swift
supacode/Info.plist
SupacodeSettingsShared/Support/SupacodePaths.swift
supacode-cli/Transport/SocketDiscovery.swift
supacode/Clients/Deeplink/DeeplinkClient.swift
supacode/Clients/Zmx/ZmxClient.swift
supacode/Infrastructure/AgentHookSocketServer.swift
supacode/Infrastructure/Ghostty/GhosttyRuntime.swift
supacode/Features/Repositories/Views/WorktreeDetailView.swift
supacode/Features/Terminal/TabBar/Views/TerminalTabBarView.swift'

last=$(gh issue list --repo "$repo" --label upstream-digest --state all \
  --limit 1 --json body --jq '.[0].body' 2>/dev/null |
  sed -n 's/.*digest-marker:\([0-9a-f]\{40\}\).*/\1/p' || true)
if [ -z "$last" ] || ! git cat-file -e "$last" 2>/dev/null; then
  last=$(git merge-base HEAD upstream/main)
fi

if [ "$last" = "$upstream_sha" ]; then
  echo "No new upstream commits since $last"
  exit 0
fi

count=$(git rev-list --count "$last..upstream/main")
commits=$(git log --date=short --pretty='- %ad `%h` %s' "$last..upstream/main" | head -100)
risky=$(git diff --name-only "$last..upstream/main" | grep -Fx -f <(printf '%s\n' "$fork_files") || true)
new_tags=$(git tag --sort=-creatordate --merged upstream/main --no-merged "$last" 2>/dev/null | head -5 || true)

risk_section="✅ No changes to files this fork modifies."
if [ -n "$risky" ]; then
  risk_section=$(printf '⚠️ **Touches files this fork modifies (merge-conflict risk):**\n%s' \
    "$(printf '%s\n' "$risky" | sed 's/^/- `/;s/$/`/')")
fi

tag_section=""
if [ -n "$new_tags" ]; then
  tag_section=$(printf '**New releases:** %s' "$(printf '%s' "$new_tags" | tr '\n' ' ')")
fi

truncation_note=""
if [ "$count" -gt 100 ]; then
  truncation_note="…truncated at 100 commits; see the compare link for the rest."
fi

body=$(cat <<EOF
Weekly digest of upstream [supabitapp/supacode](https://github.com/supabitapp/supacode) changes not yet merged into this fork.

**$count new commit(s)** since \`${last:0:10}\`.

$tag_section

$risk_section

<details><summary>Commits</summary>

$commits
$truncation_note
</details>

Full diff: https://github.com/supabitapp/supacode/compare/${last}...${upstream_sha}

To take these: \`git fetch upstream && git merge upstream/main\` on the \`dupacode\` branch, then rebuild.

<!-- digest-marker:${upstream_sha} -->
EOF
)

gh label create upstream-digest --repo "$repo" --color 0e8a16 \
  --description "Automated upstream change digests" 2>/dev/null || true
gh issue create --repo "$repo" --label upstream-digest \
  --title "Upstream digest: $count new commit(s) ($(date -u +%Y-%m-%d))" \
  --body "$body"
