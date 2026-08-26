#!/bin/sh
# The addresses this machine can be reached at, resolved at run time rather than
# written into a config file.
#
# This exists because the app cannot answer "where do I open this". It prints the
# loopback address it bound, while users arrive through the TLS front door on 443,
# so the reachable address has to be derived from the live interfaces -- which is
# also what makes a DHCP lease change or a move to another network a restart
# instead of an edit.
#
# Usage:
#   local-authorities.sh primary    the single address to show a user
#   local-authorities.sh trusted    every authority, space separated
#
# `trusted` is not used by the service: nginx presents requests as loopback, so
# the app's browser-trust fence needs no list. It is kept for an operator who
# re-enables that fence and wants the entries this machine would declare.
set -eu

# Global-scope IPv4 only. Scope excludes loopback, and IPv4-only matters for the
# `trusted` list: the fence validates each entry as a bare authority and refuses
# unbracketed IPv6, so one v6 address there would abort service start rather than
# be ignored. Bridge addresses from Docker and friends are kept -- an extra
# unreachable entry costs nothing, while guessing which bridge is "real" would
# eventually drop the address someone actually uses.
ipv4_globals() {
  ip -4 -o addr show scope global 2>/dev/null | awk '{ split($4, a, "/"); print a[1] }'
}

# The source address the kernel would use to leave this machine -- the one a user
# on the network reaches. The destination is never contacted; `ip route get` only
# consults the routing table, so this works with no connectivity at all.
primary_address() {
  ip route get 1.1.1.1 2>/dev/null | sed -n 's/.* src \([0-9.]*\).*/\1/p' | head -1
}

case "${1:-primary}" in
  primary)
    address="$(primary_address)"
    [ -n "$address" ] || address="$(ipv4_globals | head -1)"
    # No network at all: still print something a local browser can open.
    [ -n "$address" ] || address='127.0.0.1'
    printf '%s\n' "$address"
    ;;
  trusted)
    # Lowercased and de-duplicated because the fence canonicalizes before
    # comparing, so differing spellings of one name are noise, and `hostname`
    # and `hostname -f` agree on most machines.
    {
      ipv4_globals
      hostname 2>/dev/null || true
      hostname -f 2>/dev/null || true
      printf 'localhost\n'
    } | tr 'A-Z' 'a-z' | awk 'NF && !seen[$0]++' | tr '\n' ' '
    printf '\n'
    ;;
  *)
    printf 'usage: %s [primary|trusted]\n' "$0" >&2
    exit 2
    ;;
esac
