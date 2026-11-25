#!/bin/bash
# platform-setup: installs every Holospace / Hologrowth project on a Mac with one command.
#
#   curl -fsSL https://raw.githubusercontent.com/holospace-saas/platform-setup/main/setup-mac.sh | bash
#
# Run it from the folder where the projects should live (for example ~/Projects or a folder on an
# external disk). It installs Homebrew and the GitHub CLI if they are missing, signs in to GitHub,
# clones (or updates) the private platform-workspace repo there and hands over to its setup-mac.sh,
# which clones the rest, installs Claude and verifies everything.
#
# This repo is public on purpose and holds nothing private: the projects themselves stay private and
# are only downloaded after signing in with an account that has access to them.
#
# Everything runs inside main(), called on the last line, so a partially downloaded script never runs.

set -euo pipefail

WORKSPACE_REPO="holospace-saas/platform-workspace"
WORKSPACE_PATH="business/platform/platform-workspace"

say()  { printf '\n=== %s\n' "$1"; }
fail() { printf '\nERROR: %s\n' "$1" >&2; exit 1; }

# When run as `curl ... | bash`, stdin is the script itself: interactive steps must read the terminal.
# Use the terminal's real device (/dev/ttysNNN), not /dev/tty: Claude Code runs on Bun, which cannot
# watch /dev/tty with kqueue on macOS and crashes ("EINVAL: invalid argument, kqueue").
term_dev() {
  local t; t="$(ps -o tty= -p $$ 2>/dev/null | tr -d ' ')"
  case "$t" in ''|'?'|'??') ;; *) if (: <"/dev/$t") 2>/dev/null; then echo "/dev/$t"; return 0; fi ;; esac
  if (: </dev/tty) 2>/dev/null; then echo /dev/tty; return 0; fi
  return 1
}
tty_in() { local d; if d="$(term_dev)"; then "$@" <"$d"; else "$@"; fi; }

load_brew() {
  local b
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [ -x "$b" ]; then eval "$("$b" shellenv)"; return 0; fi
  done
  return 1
}

main() {
  [ "$(uname -s)" = "Darwin" ] || fail "este instalador es solo para macOS."
  local base ws
  base="$(pwd)"
  ws="$base/$WORKSPACE_PATH"
  echo "Los proyectos se instalan en: $base"

  say "Homebrew"
  if command -v brew >/dev/null 2>&1 || load_brew; then
    echo "ok"
  else
    echo "No está instalado: instalándolo (puede pedir la contraseña de la Mac)..."
    tty_in /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    load_brew || fail "Homebrew no quedó instalado; revisá los mensajes de arriba."
    echo "ok"
  fi

  say "GitHub CLI"
  command -v git >/dev/null 2>&1 || brew install git
  command -v gh  >/dev/null 2>&1 || brew install gh
  if ! gh auth status >/dev/null 2>&1; then
    echo "Iniciá sesión en GitHub con la cuenta que tiene acceso a los proyectos (se abre el navegador)."
    tty_in gh auth login --hostname github.com --git-protocol https --web
  fi
  gh auth setup-git
  echo "ok: sesión de $(gh api user -q .login)"
  gh repo view "$WORKSPACE_REPO" --json name >/dev/null 2>&1 \
    || fail "la cuenta $(gh api user -q .login) no tiene acceso a $WORKSPACE_REPO."

  say "platform-workspace"
  if [ -d "$ws/.git" ]; then
    if [ -z "$(git -C "$ws" status --porcelain)" ]; then
      git -C "$ws" pull -q --ff-only && echo "ok: actualizado a la última versión"
    else
      echo "ok: ya está (tiene cambios locales, no lo actualizo)"
    fi
  elif [ -e "$ws" ]; then
    fail "$ws existe pero no es un repo de git; movelo o borralo y volvé a correr."
  else
    mkdir -p "$(dirname "$ws")"
    gh repo clone "$WORKSPACE_REPO" "$ws" -- -q && echo "ok: clonado"
  fi

  say "Instalación completa (platform-workspace/setup-mac.sh)"
  tty_in bash "$ws/setup-mac.sh"
}

main "$@"
