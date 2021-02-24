#!/bin/bash
set -u

# Check if script is run non-interactively (e.g. CI)
# If it is run non-interactively we should not prompt for passwords.
if [[ ! -t 0 || -n "${CI-}" ]]; then
  NONINTERACTIVE=1
fi

# string formatters
if [[ -t 1 ]]; then
  tty_escape() { printf "\033[%sm" "$1"; }
else
  tty_escape() { :; }
fi
tty_mkbold() { tty_escape "1;$1"; }
tty_underline="$(tty_escape "4;39")"
tty_blue="$(tty_mkbold 34)"
tty_red="$(tty_mkbold 31)"
tty_bold="$(tty_mkbold 39)"
tty_reset="$(tty_escape 0)"

shell_join() {
  local arg
  printf "%s" "$1"
  shift
  for arg in "$@"; do
    printf " "
    printf "%s" "${arg// /\ }"
  done
}

chomp() {
  printf "%s" "${1/"$'\n'"/}"
}

ohai() {
  printf "${tty_blue}==>${tty_bold} %s${tty_reset}\n" "$(shell_join "$@")"
}

warn() {
  printf "${tty_red}Warning${tty_reset}: %s\n" "$(chomp "$1")"
}

abort() {
  printf "\n${tty_red}Error${tty_reset}: %s\n\n" "$(chomp "$1")"
  exit 1
}

execute() {
  if ! "$@"; then
    abort "$(printf "Failed during: %s" "$(shell_join "$@")")"
  fi
}

if [ ! -d ".git" ]; then
    abort "No .git/ directory found. Please run inside a git repository."
    exit 1
fi

PWD=$(pwd)
HOOKS_DIR=".git/hooks/"

cd $HOOKS_DIR 2> /dev/null || abort "No .git/hooks/ directory. Did you clone and/or pull the repo?"

curl -o commit-msg -s https://raw.githubusercontent.com/adyptation/build-tools/main/commit-msg
/bin/chmod u+rwx commit-msg

git config --global pull.rebase true

git config --global fetch.prune true

git config --global diff.colorMoved zebra