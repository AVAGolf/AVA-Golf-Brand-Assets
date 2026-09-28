#!/usr/bin/env bash
# Works out which brand pack version this run publishes, if any.
#
# .github/workflows/build-brand-pack.yml runs this file, and so do the tests
# that went with it, so the logic that was tested is the logic that runs.
#
# Usage: brand-pack-version.sh <out-dir>
#
# Environment:
#   EVENT_NAME   GitHub event name: push or workflow_dispatch (default push)
#   BUMP_INPUT   the workflow_dispatch "bump" input: patch, minor or major
#   GITHUB_OUTPUT / GITHUB_STEP_SUMMARY   set by Actions; optional elsewhere
#
# Writes <out-dir>/changes.md (release notes, and the body of the zip's
# CHANGES.md) and these step outputs:
#   publish       true, or false when there is nothing to publish
#   version       X.Y.Z
#   tag           brand-pack-vX.Y.Z
#   previous      the newest tag before this run, or empty
#   bump          baseline, patch, minor, major or republish
#   reason        one line saying why
#   tag_exists    true when republishing a version that is already tagged
#   changes_file  path to changes.md
#   published     ISO 8601 UTC timestamp for this publish
#
# Versions come from git tags alone. The newest brand-pack-vX.Y.Z tag is the
# version currently on brand.avagolf.com; if pack content changed since that
# tag, the next version is published. Nothing else stores a version.

set -euo pipefail

out_dir=${1:?usage: brand-pack-version.sh <out-dir>}
event=${EVENT_NAME:-push}
bump_input=${BUMP_INPUT:-}
output=${GITHUB_OUTPUT:-/dev/null}
summary=${GITHUB_STEP_SUMMARY:-/dev/null}

tag_prefix=brand-pack-v
baseline_note="Baseline: the pack as published on brand.avagolf.com before versioning."

# What counts as pack content: everything that goes into the zip except the
# repo's own README, which describes the repo rather than the pack. The last
# entry mirrors the zip's --exclude "*.git*", so a file that never reaches the
# zip (a nested .gitkeep, a .gitattributes) cannot bump the version either.
pack=(. ':(exclude)README.md' ':(exclude).gitignore' ':(exclude).github' ':(exclude)*.git*')

case "$bump_input" in
  '' | patch | minor | major) ;;
  *)
    echo "::error::The bump input must be patch, minor or major, not '$bump_input'."
    exit 1
    ;;
esac
manual=false
[ "$event" = workflow_dispatch ] && manual=true

mkdir -p "$out_dir"
out_dir=$(cd "$out_dir" && pwd)
changes_file="$out_dir/changes.md"
# The pathspecs below are relative to the repository root.
cd "$(git rev-parse --show-toplevel)"
published=$(date -u +%Y-%m-%dT%H:%M:%SZ)

set_output() { printf '%s=%s\n' "$1" "$2" >>"$output"; }

# Newest first by version order. Anything not shaped brand-pack-vX.Y.Z is
# ignored rather than allowed to sort to the top.
tags=$(git tag --list "${tag_prefix}*" --sort=-v:refname |
  awk -v p="$tag_prefix" 'index($0, p) == 1 && substr($0, length(p) + 1) ~ /^[0-9]+\.[0-9]+\.[0-9]+$/')
last=$(printf '%s\n' "$tags" | sed -n 1p)
prev=$(printf '%s\n' "$tags" | sed -n 2p)

# render_changes FROM TO: the pack's file changes between two commits as a
# Markdown list, grouped Added / Modified / Renamed / Deleted.
render_changes() {
  local from=$1 to=$2 raw status path old new
  local added='' modified='' renamed='' deleted=''
  local n_added=0 n_modified=0 n_renamed=0 n_deleted=0
  raw=$(mktemp)
  # -z: paths arrive verbatim (spaces, accents), never quoted or escaped.
  git diff --name-status -z -M "$from" "$to" -- "${pack[@]}" >"$raw"
  while IFS= read -r -d '' status; do
    case "$status" in
      R* | C*)
        IFS= read -r -d '' old
        IFS= read -r -d '' new
        if [ "${status#?}" = 100 ]; then
          renamed+="- \`$old\` → \`$new\`"$'\n'
        else
          renamed+="- \`$old\` → \`$new\` (content changed too)"$'\n'
        fi
        n_renamed=$((n_renamed + 1))
        ;;
      *)
        IFS= read -r -d '' path
        case "$status" in
          A)
            added+="- \`$path\`"$'\n'
            n_added=$((n_added + 1))
            ;;
          D)
            deleted+="- \`$path\`"$'\n'
            n_deleted=$((n_deleted + 1))
            ;;
          *)
            modified+="- \`$path\`"$'\n'
            n_modified=$((n_modified + 1))
            ;;
        esac
        ;;
    esac
  done <"$raw"
  rm -f "$raw"

  local total=$((n_added + n_modified + n_renamed + n_deleted)) parts=''
  [ "$n_added" -gt 0 ] && parts+=", $n_added added"
  [ "$n_modified" -gt 0 ] && parts+=", $n_modified modified"
  [ "$n_renamed" -gt 0 ] && parts+=", $n_renamed renamed"
  [ "$n_deleted" -gt 0 ] && parts+=", $n_deleted deleted"
  local files=files
  [ "$total" -eq 1 ] && files=file

  # shellcheck disable=SC2016 # the backticks are Markdown, not a subshell
  printf 'Changes since %s (`%s`): %d %s (%s).\n' "${from#"$tag_prefix"}" "$from" "$total" "$files" "${parts#, }"
  [ -n "$added" ] && printf '\n**Added (%d)**\n\n%s' "$n_added" "$added"
  [ -n "$modified" ] && printf '\n**Modified (%d)**\n\n%s' "$n_modified" "$modified"
  [ -n "$renamed" ] && printf '\n**Renamed (%d)**\n\n%s' "$n_renamed" "$renamed"
  [ -n "$deleted" ] && printf '\n**Deleted (%d)**\n\n%s' "$n_deleted" "$deleted"
  return 0
}

# The newest commit since $last whose message contains MARKER, as "sha subject".
find_marker() {
  git log --fixed-strings --regexp-ignore-case --grep="$1" --format='%h %s' "$last..HEAD" | sed -n 1p
}

if [ -z "$last" ]; then
  # First run: today's pack is what the site already calls 1.0.0. Publish it
  # under that number so the manifest exists and there is a tag to diff from.
  version=1.0.0
  bump=baseline
  reason="baseline: no ${tag_prefix}X.Y.Z tag yet, so the current pack is published as 1.0.0"
  if [ "$manual" = true ] && [ -n "$bump_input" ]; then
    reason+=" (the '$bump_input' input does not apply to the baseline)"
  fi
  tag_exists=false
  printf '%s\n' "$baseline_note" >"$changes_file"
else
  changed=false
  rc=0
  git diff --quiet "$last" HEAD -- "${pack[@]}" || rc=$?
  case "$rc" in
    0) ;;
    1) changed=true ;;
    *)
      echo "::error::git diff $last HEAD failed (exit $rc)."
      exit "$rc"
      ;;
  esac

  if [ "$changed" = false ]; then
    if [ "$manual" = false ]; then
      echo "::notice::No pack content changed since $last; nothing to publish."
      set_output publish false
      set_output previous "$last"
      # shellcheck disable=SC2016 # the backticks are Markdown, not a subshell
      printf '## Brand pack: nothing to publish\n\nNo pack content changed since `%s`, so %s stays the current version.\n' \
        "$last" "${last#"$tag_prefix"}" >>"$summary"
      exit 0
    fi
    # Manual run with nothing new: the repair path. Rebuild and re-upload the
    # same version without bumping, with the notes that version shipped with.
    version=${last#"$tag_prefix"}
    bump=republish
    reason="republish: manual run and no pack content changed since $last, so $version is rebuilt and uploaded again as-is"
    if [ "$bump_input" = minor ] || [ "$bump_input" = major ]; then
      reason+=" (the '$bump_input' input only applies when pack content changed)"
    fi
    tag_exists=true
    if [ -n "$prev" ]; then
      render_changes "$prev" "$last" >"$changes_file"
    else
      printf '%s\n' "$baseline_note" >"$changes_file"
    fi
  else
    major_hit=$(find_marker '[major]')
    minor_hit=$(find_marker '[minor]')
    if [ "$manual" = true ] && [ -n "$bump_input" ]; then
      bump=$bump_input
      reason="$bump: chosen on the manual run"
    elif [ -n "$major_hit" ]; then
      bump=major
      reason="major: [major] in $major_hit"
    elif [ -n "$minor_hit" ]; then
      bump=minor
      reason="minor: [minor] in $minor_hit"
    else
      bump=patch
      reason="patch: the default; no commit since $last says [minor] or [major]"
    fi

    IFS=. read -r x y z <<EOF
${last#"$tag_prefix"}
EOF
    # 10# keeps a stray leading zero from being read as octal.
    x=$((10#$x)) y=$((10#$y)) z=$((10#$z))
    case "$bump" in
      major) x=$((x + 1)) y=0 z=0 ;;
      minor) y=$((y + 1)) z=0 ;;
      patch) z=$((z + 1)) ;;
    esac
    version="$x.$y.$z"
    tag_exists=false
    if git rev-parse --quiet --verify "refs/tags/$tag_prefix$version" >/dev/null; then
      echo "::error::$tag_prefix$version already exists but is not the newest tag ($last). Sort the tags out by hand."
      exit 1
    fi
    render_changes "$last" HEAD >"$changes_file"
  fi
fi

tag="$tag_prefix$version"
echo "Brand pack $version ($tag): $reason"

set_output publish true
set_output version "$version"
set_output tag "$tag"
set_output previous "$last"
set_output bump "$bump"
set_output reason "$reason"
set_output tag_exists "$tag_exists"
set_output changes_file "$changes_file"
set_output published "$published"
