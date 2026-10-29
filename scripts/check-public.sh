#!/usr/bin/env bash
# Scans what this repo would publish for secrets, tokens, IPs, tailnet names, machine paths, emails and em
# dashes, then for the names in a private deny list (personal hostnames, employer products and clients), which
# stays out of the repo because listing them here would publish them.
#
# Usage: scripts/check-public.sh [--skip-private]
# Deny list: $CLAUDE_KIT_DENYLIST, or scripts/denylist.local (gitignored). One extended regex per line,
# matched case-insensitively; blank lines and lines starting with # are ignored.
# A line that contains "check-public: allow" is never reported.
# Exit codes: 0 clean, 1 findings, 2 the deny list is missing.
set -euo pipefail

# Git runs hooks from the top of the work tree, and a symlinked hook's own path points into .git/hooks.
root="$(git rev-parse --show-toplevel 2>/dev/null || (cd "$(dirname "$0")/.." && pwd))"
cd "$root"
self="scripts/check-public.sh"
denylist="${CLAUDE_KIT_DENYLIST:-scripts/denylist.local}"
skip_private=0
[ "${1:-}" = "--skip-private" ] && skip_private=1

# The files a commit would carry: tracked plus untracked-but-not-ignored, without the scanner itself.
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
	files=$( { git ls-files; git ls-files --others --exclude-standard; } | sort -u | grep -vxF "$self" | grep -vxF "$denylist" || true)
else
	files=$(find . -type f -not -path './.git/*' | sed 's|^\./||' | grep -vxF "$self" | grep -vxF "$denylist")
fi

found=0
report() { # <label> <grep -E flags> <pattern> [exclude pattern, applied to each match]
	local label="$1" flags="$2" pattern="$3" exclude="${4:-}" hits
	# shellcheck disable=SC2086
	hits=$(printf '%s\n' "$files" | tr '\n' '\0' | xargs -0 grep -nIE $flags -- "$pattern" 2>/dev/null \
		| grep -v 'check-public: allow' || true)
	if [ -n "$exclude" ] && [ -n "$hits" ]; then
		# Keep a line only if one of its matches is not excluded: a loopback address next to a real one still counts.
		hits=$(printf '%s\n' "$hits" | while IFS= read -r line; do
			if printf '%s\n' "${line#*:*:}" | grep -oE $flags -- "$pattern" | grep -vqE -- "$exclude"; then
				printf '%s\n' "$line"
			fi
		done)
	fi
	if [ -n "$hits" ]; then
		printf '\n== %s\n%s\n' "$label" "$hits"
		found=1
	fi
}

report "private key" "" '-----BEGIN [A-Z ]*PRIVATE KEY-----'
report "GitHub token" "" '(ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{20,}'
report "Anthropic or OpenAI key" "" 'sk-(ant-)?[A-Za-z0-9_-]{20,}'
report "AWS access key" "" '(AKIA|ASIA)[0-9A-Z]{16}'
report "Slack token" "" 'xox[abposr]-[A-Za-z0-9-]{10,}'
report "Google API key" "" 'AIza[0-9A-Za-z_-]{35}'
report "JWT" "" 'eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.'
report "Infisical token" "" 'st\.[0-9a-f-]{36}\.'
report "Garage key id" "" '\bGK[0-9a-f]{24}\b'
report "long hex secret" "" '\b[0-9a-f]{40,}\b'
report "secret assignment" "-i" '(password|passwd|secret|token|api[_-]?key)["'"'"']?[[:space:]]*[:=][[:space:]]*["'"'"'][^"'"'"'[:space:]]{12,}["'"'"']'
report "UUID (project or resource id)" "-i" '\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b'
report "IPv4 address" "" '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' '\b(127\.0\.0\.1|0\.0\.0\.0)\b'
report "tailnet name" "-i" '\.ts\.net\b|\btail[0-9a-f]{5,}\b'
report "machine path" "" '/Users/[A-Za-z]|/home/[a-z]'
report "email address" "-i" '[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[a-z]{2,}' '@example\.(com|org|net)|noreply@'
report "em dash" "" '—'

if [ -f "$denylist" ]; then
	while IFS= read -r pattern || [ -n "$pattern" ]; do
		case "$pattern" in '' | '#'*) continue ;; esac
		report "private name /$pattern/" "-i" "$pattern"
	done <"$denylist"
elif [ "$skip_private" = 1 ]; then
	echo "warning: no deny list at $denylist; private names were NOT checked" >&2
else
	echo "error: no deny list at $denylist. Copy scripts/denylist.example and fill it, or pass --skip-private." >&2
	exit 2
fi

if [ "$found" = 1 ]; then
	printf '\ncheck-public: findings above. Fix them, or mark an intended line with "check-public: allow".\n' >&2
	exit 1
fi
echo "check-public: clean ($(printf '%s\n' "$files" | grep -c .) files)"
