#!/usr/bin/env bash
# Resolve this workspace's Pi session transcripts and print them as JSON lines.
#
# Pi stores one plain JSONL file per session under
#   $PI_CODING_AGENT_DIR/sessions/<encoded-cwd>/<timestamp>_<session-id>.jsonl
# (default root ~/.pi/agent). The directory name is the working directory with the leading /
# dropped, every other / and : replaced by -, and wrapped in --, so /home/pi/projects/x becomes
# --home-pi-projects-x--.
#
# Usage:
#   scripts/audit-log.sh                     newest session for the current directory
#   scripts/audit-log.sh --list              every session for this directory, newest first
#   scripts/audit-log.sh --dir <path>        a different working directory
#   scripts/audit-log.sh --session <id>      one exact session id
#   scripts/audit-log.sh --raw               print the transcript path instead of its contents
set -euo pipefail

agent_dir="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"
target_dir="$PWD"
mode=newest
session_id=""
raw=0

while [ $# -gt 0 ]; do
  case "$1" in
    --list) mode=list; shift ;;
    --raw) raw=1; shift ;;
    --dir) target_dir="$2"; shift 2 ;;
    --session) session_id="$2"; mode=exact; shift 2 ;;
    -h|--help) sed -n '2,15p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

encode_dir() {
  printf -- '--%s--' "$(printf '%s' "$1" | sed 's|^/||; s|[/:]|-|g')"
}

sessions_root="$agent_dir/sessions/$(encode_dir "$target_dir")"

if [ ! -d "$sessions_root" ]; then
  echo "no sessions for $target_dir" >&2
  echo "looked in $sessions_root" >&2
  exit 1
fi

emit() {
  local file="$1"
  if [ "$raw" = 1 ]; then
    printf '%s\n' "$file"
  else
    cat "$file"
  fi
}

case "$mode" in
  newest)
    file=$(ls -t "$sessions_root"/*.jsonl 2>/dev/null | head -1 || true)
    [ -n "$file" ] || { echo "no transcript files in $sessions_root" >&2; exit 1; }
    echo "# $file" >&2
    emit "$file"
    ;;
  list)
    for f in $(ls -t "$sessions_root"/*.jsonl 2>/dev/null); do
      size=$(wc -c < "$f")
      mtime=$(date -r "$f" '+%Y-%m-%dT%H:%M:%SZ')
      printf '%s\t%s\t%s\n' "$mtime" "$size" "$f"
    done
    ;;
  exact)
    file=$(ls "$sessions_root"/*_"$session_id".jsonl 2>/dev/null | head -1 || true)
    [ -n "$file" ] || { echo "no such session: $session_id" >&2; exit 1; }
    emit "$file"
    ;;
esac
