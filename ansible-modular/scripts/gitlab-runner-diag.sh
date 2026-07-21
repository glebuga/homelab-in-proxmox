#!/usr/bin/env bash
# ===========================================================================
# gitlab-runner-diag.sh — быстрая диагностика GitLab Runner "вручную".
# Запуск на хосте с раннером:  sudo ./gitlab-runner-diag.sh
# Или удалённо с control-машины: ansible gitlab -i inventory -m script -a scripts/gitlab-runner-diag.sh
# По умолчанию печатает отчёт и сохраняет в /tmp/gitlab_runner_report.txt
# (можно задать OUT=/dev/stdout чтобы только напечатать).
# ===========================================================================
set -euo pipefail

OUT="${OUT:-/tmp/gitlab_runner_report.txt}"
CONF="${GITLAB_RUNNER_CONFIG:-/etc/gitlab-runner/config.toml}"

URL="$(grep -oE 'url = "[^"]+"' "$CONF" 2>/dev/null | head -1 | sed -E 's/url = "(.*)"/\1/' || echo 'n/a')"
EXEC="$(grep -oE 'executor = "[^"]+"' "$CONF" 2>/dev/null | head -1 | sed -E 's/executor = "(.*)"/\1/' || echo 'n/a')"
TOKEN="$(grep -oE 'token = "[^"]+"' "$CONF" 2>/dev/null | head -1 | sed -E 's/token = "(.*)"/\1/' || echo 'n/a')"
HOSTFQDN="$(echo "$URL" | sed -E 's#^https?://##; s#/.*##')"
REACH="$(curl -sS -o /dev/null -w 'HTTP %{http_code}' "${URL}/api/v4/runners" 2>/dev/null || echo 'FAILED')"
SVC="$(systemctl is-active gitlab-runner 2>/dev/null || echo unknown)"
ENABLED="$(systemctl is-enabled gitlab-runner 2>/dev/null || echo unknown)"
VERIFY="$(gitlab-runner verify 2>&1 | grep -iE 'verifying runner|is valid|error' | head -2 || true)"
LOG="$(journalctl -u gitlab-runner -n 8 --no-pager 2>/dev/null | tail -8 || true)"

if echo "$VERIFY" | grep -qi "is valid"; then
  STATUS="RUNNER OK — connected and authorized to $URL"
else
  STATUS="CHECK NEEDED — see verify output / logs above"
fi

{
  echo "==============================================================="
  echo " GitLab Runner Diagnostic Report"
  echo " Generated: $(date '+%Y-%m-%d %H:%M:%S')"
  echo " Host:     $(hostname) ($(hostname -I | awk '{print $1}'))"
  echo "==============================================================="
  echo
  echo "GITLAB CONNECTION"
  echo "---------------------------------------------------------------"
  echo " GitLab URL : $URL"
  echo " GitLab host: $HOSTFQDN"
  echo " TLS CA file: ${GITLAB_RUNNER_TLS_CA_FILE:-/etc/gitlab/ssl/gitlab.home.local.crt}"
  echo " TLS skip  : ${GITLAB_RUNNER_TLS_SKIP_VERIFY:-true}"
  echo " Reachable : $REACH"
  echo
  echo "RUNNER"
  echo "---------------------------------------------------------------"
  echo " Name      : ${GITLAB_RUNNER_NAME:-$(hostname)}"
  echo " Executor  : $EXEC"
  echo " Tags      : ${GITLAB_RUNNER_TAGS:-local,shell}"
  echo " Concurrent: ${GITLAB_RUNNER_CONCURRENT:-2}"
  echo " Token     : ${TOKEN:0:12}... (glrt-*, hidden)"
  echo " Config    : $CONF"
  echo
  echo "SERVICE"
  echo "---------------------------------------------------------------"
  echo " Status    : $SVC"
  echo " Enabled   : $ENABLED"
  echo
  echo "VERIFY (gitlab-runner verify)"
  echo "---------------------------------------------------------------"
  echo "$VERIFY"
  echo
  echo "RECENT LOG (last lines)"
  echo "---------------------------------------------------------------"
  echo "$LOG"
  echo
  echo "==============================================================="
  echo " STATUS: $STATUS"
  echo "==============================================================="
} | tee "$OUT"
