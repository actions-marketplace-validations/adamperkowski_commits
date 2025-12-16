#! /usr/bin/env bash
# check-commit-message
# Copyright (c) 2025 Adam Perkowski

set -eo pipefail

SCRIPT='check-commit-message'

if [ "$#" -ne 1 ]; then
  echo "usage: $SCRIPT <message>"
  exit 1
fi

if [ -z "$SCOPES" ]; then
  echo "SCOPES environment variable is not set. all scopes allowed."
fi

raw_input="$1"
allowed_scopes="$SCOPES"

check_message() {
  local message="$1"
  local scope="${message%%:*}"
  local subject_body="${message#*: }"

  readarray -t full_lines <<<"$message"
  readarray -t body_lines <<<"$subject_body"

  if [[ "$message" =~ ';' ]]; then
    echo "message cannot contain semicolons"
    return 1
  fi

  check_header "${full_lines[0]}" || return 1
  check_scope "$scope" || return 1
  check_subject "${body_lines[0]}" || return 1
  check_body "${body_lines[@]}" || return 1

  return 0
}

check_header() {
  local header="$1"

  if ((${#header} > 50)); then
    echo "header cannot exceed 50 characters"
    return 1
  fi
}

check_scope() {
  local scope="$1"

  if [[ -z "$scope" ]]; then
    echo "scope cannot be empty"
    return 1
  fi

  if [[ "$scope" =~ ' ' ]]; then
    echo "scope cannot contain spaces"
    return 1
  fi

  if [[ -n "$allowed_scopes" ]] && [[ ! " ${allowed_scopes[*]} " =~ ${scope} ]]; then
    echo "invalid scope:  ${scope}"
    echo "allowed scopes: ${allowed_scopes[*]}"
    return 1
  fi
}

check_subject() {
  local subject="$1"

  if [[ ! "${subject}" =~ ^[a-z0-9] ]] || ! [[ "${subject: -1}" =~ [a-z0-9]$ ]]; then
    echo "subject must start with a lowercase letter and end with a lowercase letter or number"
    return 1
  fi
}

check_body() {
  body=("$@")
  if [[ "${body[1]}" != "" ]]; then
    echo "second line must be empty"
    return 1
  fi

  if [[ -z "${body[2]}" ]]; then
    return 0
  fi

  for line in "${body[@]:2}"; do
    if ((${#line} > 72)); then
      echo "body lines cannot exceed 72 characters"
      return 1
    fi
  done
}

messages=()
while [[ "$raw_input" ]]; do
  if ! [[ "$raw_input" =~ '; ' ]]; then
    messages+=("$raw_input")
    break
  fi

  messages+=("${raw_input%%; *}")
  raw_input="${raw_input#*; }"
done

for msg in "${messages[@]}"; do
  echo "checking '$msg'"

  if ! check_message "$msg"; then
    exit 1
  fi
done

echo "all good :3"
exit 0
