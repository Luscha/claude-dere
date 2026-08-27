#!/usr/bin/env bash
# claude-dere style validator
#
#   ./validate.sh                 validate every style
#   ./validate.sh styles/x.md     validate specific files
#
# Checks that a style file is SHAPED like one that could work. It cannot tell you
# whether the persona is any good — that is the strip test, and it is a judgment
# call no script can make. See docs/writing-your-own.md#the-strip-test.
#
# Four styles were cut from this repo for being pure vocabulary. All four passed
# every check below. Shape is not the bar.
set -uo pipefail

RED=$'\033[38;5;203m'; GRN=$'\033[38;5;114m'; YEL=$'\033[38;5;179m'
DIM=$'\033[2m'; BLD=$'\033[1m'; OFF=$'\033[0m'

FAILED=0; WARNED=0; CHECKED=0

fail() { printf '  %s✗%s %-22s %s\n' "$RED" "$OFF" "$1" "$2"; FAILED=1; FILE_BAD=1; }
warn() { printf '  %s!%s %-22s %s\n' "$YEL" "$OFF" "$1" "$2"; WARNED=1; }
pass() { printf '  %s✓%s %s\n' "$GRN" "$OFF" "$1"; }

# has <file> <regex> — line-anchored, for headings and frontmatter keys
has() { grep -qiE "$2" "$1"; }
# flat <file> <regex> — whitespace-normalised, so a phrase split across a line
# wrap still matches. Prose checks must use this.
flat() { tr '\n' ' ' < "$1" | tr -s ' ' | grep -qiE "$2"; }

validate() {
  local f="$1"; FILE_BAD=0
  printf '\n%s%s%s\n' "$BLD" "$f" "$OFF"
  CHECKED=$((CHECKED + 1))

  # -- frontmatter -----------------------------------------------------------
  if [[ "$(head -1 "$f")" != "---" ]]; then
    fail "frontmatter" "file must open with ---"
  elif ! grep -qE '^name: .+' "$f" || ! grep -qE '^description: .+' "$f"; then
    fail "frontmatter" "needs both name: and description:"
  else
    pass "frontmatter"
  fi

  # -- 1. unconditional baseline generator -----------------------------------
  # The #1 failure: a persona whose every trait is trigger-gated goes silent on
  # an ordinary turn.
  if has "$f" '^#+ .*(baseline|the engine|engines?|core mechanic)'; then
    if flat "$f" '(every message|no trigger required|needs? no(thing)? (input|trigger)|without a trigger|self-trigger|fires on a bare)'; then
      pass "baseline generator"
    else
      fail "baseline generator" "section exists but never says it fires unconditionally"
    fi
  else
    fail "baseline generator" "no baseline/engine section — persona will be inert"
  fi

  # -- 2. self-check ---------------------------------------------------------
  if flat "$f" 'self-check'; then
    pass "self-check"
  else
    fail "self-check" "add: if this could pass as the default style, it failed"
  fi

  # -- 3. mid-explanation modifier -------------------------------------------
  # Without this the persona brackets the content instead of entering it.
  if flat "$f" '(mid-explanation|interrupts a technical sentence)'; then
    pass "mid-explanation modifier"
  else
    fail "mid-explanation modifier" "persona will bracket content, not enter it"
  fi

  # -- 4. worked examples ----------------------------------------------------
  local n
  n=$(grep -cE '^> ' "$f")
  if ! has "$f" '^#+ .*worked examples'; then
    fail "worked examples" "no '## Worked examples' section"
  elif (( n < 12 )); then
    fail "worked examples" "only $n quoted lines; rules produce fragments, examples transfer tone"
  else
    pass "worked examples ($n quoted lines)"
  fi

  # -- 5. rails --------------------------------------------------------------
  if has "$f" '^#+ .*(rails|hard limits)'; then
    pass "rails"
  else
    fail "rails" "no rails/hard-limits section"
  fi

  # -- 6. the safety rail every style needs ----------------------------------
  if flat "$f" '(drop the voice|say it straight)'; then
    pass "voice-drop rail"
  else
    fail "voice-drop rail" "must drop the persona when something genuinely matters"
  fi

  # -- 7. technical-accuracy rail --------------------------------------------
  if flat "$f" '(file paths|line numbers)[^.]{0,120}(exact|never)|never (alter|altered|withheld)'; then
    pass "accuracy rail"
  else
    fail "accuracy rail" "must state that technical content stays exact"
  fi

  # -- advisory --------------------------------------------------------------
  local lines; lines=$(wc -l < "$f")
  (( lines < 100 )) && warn "length" "$lines lines — likely underspecified"
  has "$f" '^keep-coding-instructions:' || warn "keep-coding-instructions" "not set; engineering behaviour may be dropped"

  (( FILE_BAD == 0 )) && printf '  %s%s all structural checks passed%s\n' "$DIM" "$f" "$OFF"
}

FILES=("$@")
if [[ ${#FILES[@]} -eq 0 ]]; then
  shopt -s nullglob
  FILES=("$(dirname "${BASH_SOURCE[0]}")"/styles/*.md)
fi
[[ ${#FILES[@]} -eq 0 ]] && { echo "no style files found" >&2; exit 1; }

for f in "${FILES[@]}"; do
  [[ -f "$f" ]] || { printf '%s✗%s %s: not found\n' "$RED" "$OFF" "$f"; FAILED=1; continue; }
  validate "$f"
done

printf '\n%s─────%s\n' "$DIM" "$OFF"
if (( FAILED )); then
  printf '%s✗ validation failed%s — %s file(s) checked\n' "$RED" "$OFF" "$CHECKED"
  printf '%ssee docs/writing-your-own.md for what each check is protecting against%s\n' "$DIM" "$OFF"
  exit 1
fi
printf '%s✓ %s style(s) valid%s' "$GRN" "$CHECKED" "$OFF"
(( WARNED )) && printf ' %s(with warnings)%s' "$YEL" "$OFF"
printf '\n'
