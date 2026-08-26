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
#   local-authorities.sh primary [seconds]   the single address to show a user
#   local-authorities.sh trusted             every authority, space separated
#
# `trusted` is not used by the service: nginx presents requests as loopback, so
# the app's browser-trust fence needs no list. It is kept for an operator who
# re-enables that fence and wants the entries this machine would declare.
set -eu

# How long `primary` waits for a routable address before giving up. This is not
# padding: on the deployment this was written for, the service starts 16s after
# the kernel and the wireless DHCP lease lands at 28s, because network-online is
# satisfied by a wired bridge that comes up first. Without a wait the boot-time
# announcement named a Docker bridge. The loop exits on its first iteration once
# the route exists, so a manual restart pays nothing.
PRIMARY_WAIT_DEFAULT=30

# Interfaces that have an address but are never how someone reaches this machine:
# container and VM bridges, veth pairs, tunnels, overlays. They matter because
# they are usually up BEFORE the real interface has a lease, so any "first
# address wins" fallback picks one of them at exactly the wrong moment.
is_virtual_interface() {
  case "$1" in
    lo | docker* | br-* | veth* | virbr* | tun* | tap* | wg* | zt* | cni* | flannel* | kube*) return 0 ;;
    *) return 1 ;;
  esac
}

# Global-scope IPv4 only. Scope excludes loopback, and IPv4-only matters for the
# `trusted` list: the fence validates each entry as a bare authority and refuses
# unbracketed IPv6, so one v6 address there would abort service start rather than
# be ignored.
# $1: 'physical' to skip the virtual interfaces above, otherwise every interface.
ipv4_globals() {
  ip -4 -o addr show scope global 2>/dev/null | while read -r _ device _ cidr _; do
    [ "${1:-all}" != physical ] || ! is_virtual_interface "$device" || continue
    printf '%s\n' "${cidr%%/*}"
  done
}

# The source address the kernel would use to leave this machine -- the one a user
# on the network reaches, and the only method that picks the right interface
# without guessing. The destination is never contacted; `ip route get` consults
# the routing table only, so this works on a network with no internet access. It
# yields nothing when no default route exists yet, which is the boot-time case
# the caller waits out.
routed_source() {
  ip route get 1.1.1.1 2>/dev/null | sed -n 's/.* src \([0-9.]*\).*/\1/p' | head -1
}

# Best address available right now, or nothing. The routed source is tested for
# emptiness rather than by exit status: it ends in `head`, which succeeds even
# when `sed` matched nothing, so branching on the status would always take the
# first path and the fallback below would be dead code.
best_address() {
  routed="$(routed_source)"
  if [ -n "$routed" ]; then
    printf '%s\n' "$routed"
    return 0
  fi
  # No default route: an isolated network still has a real interface, and the
  # physical filter is what keeps this from answering with a container bridge.
  ipv4_globals physical | head -1
}

case "${1:-primary}" in
  primary)
    deadline=$(( $(date +%s) + ${2:-$PRIMARY_WAIT_DEFAULT} ))
    while : ; do
      address="$(best_address)"
      [ -z "$address" ] || break
      [ "$(date +%s)" -lt "$deadline" ] || break
      sleep 1
    done
    # Out of time. A bridge address is still better than nothing -- it says the
    # service is up and the operator can re-run this once the network settles --
    # and loopback covers a machine with no network at all.
    [ -n "$address" ] || address="$(ipv4_globals all | head -1)"
    [ -n "$address" ] || address='127.0.0.1'
    printf '%s\n' "$address"
    ;;
  trusted)
    # Lowercased and de-duplicated because the fence canonicalizes before
    # comparing, so differing spellings of one name are noise, and `hostname`
    # and `hostname -f` agree on most machines. Bridge addresses are included
    # here on purpose: an extra unreachable entry in a trust list costs nothing,
    # while omitting one someone actually uses costs a 403.
    {
      ipv4_globals all
      hostname 2>/dev/null || true
      hostname -f 2>/dev/null || true
      printf 'localhost\n'
    } | tr 'A-Z' 'a-z' | awk 'NF && !seen[$0]++' | tr '\n' ' '
    printf '\n'
    ;;
  *)
    printf 'usage: %s [primary [seconds]|trusted]\n' "$0" >&2
    exit 2
    ;;
esac
