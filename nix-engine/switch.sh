#!/data/data/com.termux/files/usr/bin/sh
# Materialize the home-manager generation (TN_OUT, already placed in the
# container store by `termux-nix switch` on the PC) into the termux home as a
# SYMLINK FARM pointing at the container store's physical path. No copy, no
# proot, no on-device nix work.
#
# Why symlinks and not the store's own /nix/store paths: /nix only exists
# inside proot. The same files live natively at
#   $PREFIX/var/lib/proot-distro/containers/nix/rootfs/nix/store
# so we translate every leaf target /nix/store/X -> $STORE_PHYS/X and link
# that. Native i3/bash then read the real files straight through the symlinks.
set -eu
. "$(dirname "$0")/env.sh"

STATE=$HOME/.local/state/termux-nix
MANIFEST=$STATE/manifest
mkdir -p "$STATE"

[ -n "${TN_OUT:-}" ] || {
  echo "TN_OUT not set — run 'termux-nix switch' from the PC"; exit 1;
}
out=$TN_OUT
echo ">> using prebuilt generation: $out"

# home-files is a symlink inside the generation; resolve its raw target name
hf_raw=$(readlink "$STORE_PHYS/${out##*/}/home-files")   # /nix/store/XXX-home-manager-files
SRC=$STORE_PHYS/${hf_raw##*/}

# 1. guardrail: a config file READ NATIVELY that hardcodes /nix/store won't work
#    (/nix exists only inside proot). Skip .local/bin/* — those are proot
#    launchers and reference /nix/store on purpose (resolved via -b nix:/nix).
leak=0
for l in $(find "$SRC" -type l); do
  rel=${l#$SRC/}
  case "$rel" in .local/bin/*) continue;; esac
  t=$(readlink "$l"); case "$t" in /nix/store/*) t=$STORE_PHYS/${t#/nix/store/};; esac
  if grep -Iq /nix/store "$t" 2>/dev/null; then
    echo "LEAK: $rel content references /nix/store (read natively, would break)"; leak=1
  fi
done
[ "$leak" = 0 ] || { echo "aborting: fix the config above"; exit 1; }

# 2. materialize: real dirs -> mkdir, symlink leaves -> translated symlink
newman=$(mktemp)
( cd "$SRC" && find . -mindepth 1 ) | sed 's|^\./||' | while read rel; do
  src="$SRC/$rel"
  if [ -L "$src" ]; then
    t=$(readlink "$src"); case "$t" in /nix/store/*) t=$STORE_PHYS/${t#/nix/store/};; esac
    case "$rel" in
      # the termux app (0.119+) can't read termux.properties through a
      # symlink — materialize .termux/* as real copies instead
      .termux/*) rm -f "$HOME/$rel"; cp "$t" "$HOME/$rel" ;;
      *) ln -sfn "$t" "$HOME/$rel" ;;
    esac
    echo "$rel" >>"$newman"
  elif [ -d "$src" ]; then
    mkdir -p "$HOME/$rel"
  fi
done

# 3. prune links from the previous generation that are gone now
sort "$newman" -o "$newman"
if [ -f "$MANIFEST" ]; then
  sort "$MANIFEST" -o "$MANIFEST"
  comm -23 "$MANIFEST" "$newman" |
  while read old; do [ -L "$HOME/$old" ] && rm -f "$HOME/$old"; done
fi
cp "$newman" "$MANIFEST"; rm -f "$newman"

# root the live generation in the container so `termux-nix gc` won't reap it
mkdir -p "$CONTAINER_ROOTFS/nix/var/nix/gcroots"
ln -sfn "$out" "$CONTAINER_ROOTFS/nix/var/nix/gcroots/termux-nix"

# 4. expose all ~/.local/bin forwarders (nix, app forwarders, start-desktop) on
#    the default PATH so every shell form — incl. non-interactive `ssh host cmd`
#    — finds them. Also drop stale $PREFIX/bin links we made but no longer back.
for f in "$HOME"/.local/bin/*; do
  [ -e "$f" ] || continue
  b=${f##*/}
  ln -sf "$f" "$PREFIX/bin/$b"
done
# prune $PREFIX/bin links pointing back into ~/.local/bin that are now dangling
for l in "$PREFIX"/bin/*; do
  case "$(readlink "$l" 2>/dev/null)" in
    "$HOME"/.local/bin/*) [ -e "$l" ] || rm -f "$l";;
  esac
done

# materialize declared runit services (pkgs/services.nix) into
# $PREFIX/var/service: real dir per service (runsv writes supervise/ there),
# run symlinked to the home-managed script. Prune services we created whose
# declaration is gone (the manifest prune already dangled their run link).
SVSRC=$HOME/.config/termux-nix/service
SVDST=$PREFIX/var/service
# sv needs SVDIR; it's only set by the termux-services profile.d hook, which
# non-login shells (ssh command mode, this script) never source
export SVDIR=$SVDST
mkdir -p "$SVDST"
for d in "$SVSRC"/*/; do
  [ -e "$d/run" ] || continue
  n=${d%/}; n=${n##*/}
  mkdir -p "$SVDST/$n"
  # declared enable state: a down file blocks runsv's autostart. Place it
  # BEFORE the run link so a disabled service can't start in the gap.
  if [ -e "$d/down" ]; then
    ln -sf "$d/down" "$SVDST/$n/down"
  else
    rm -f "$SVDST/$n/down"
  fi
  ln -sf "$d/run" "$SVDST/$n/run"
  # best-effort: sv is absent before termux-services is installed (first
  # switch) and fails when runsvdir isn't up; the down file still encodes
  # the state, applied when the supervisor next starts
  if [ -e "$d/manual" ]; then
    : # manual service: runtime state driven by sv (start/stop-desktop), not switch
  elif [ -e "$d/down" ]; then
    sv down "$n" 2>/dev/null || true
  else
    sv up "$n" 2>/dev/null || true
  fi
done
for r in "$SVDST"/*/run; do
  case "$(readlink "$r" 2>/dev/null)" in
    "$SVSRC"/*) [ -e "$r" ] || { n=${r%/run}; sv exit "${n##*/}" 2>/dev/null || true; rm -rf "$n"; } ;;
  esac
done

# 5. apply live where possible
DISPLAY=:0 i3-msg reload >/dev/null 2>&1 || true
# termux.properties (enforce-char-based-input etc.) only takes effect when the
# app re-reads it — reload here so a switch always applies it.
# both reload calls IPC into an app process and block forever if android has
# frozen it (cached-app freezer) — bound them so switch can't hang
timeout 10 termux-reload-settings >/dev/null 2>&1 || true
# termux-x11 input prefs drift back (the app rewrites them from memory on
# restart), so reassert the korean-input-critical ones on every switch:
# preferScancodes=false + enforceCharBasedInput=false keep the editor a
# normal TYPE_CLASS_TEXT one so the android IME composes hardware keys
# (NOTE: enforceCharBasedInput is INVERTED vs the termux-app property —
# in termux-x11, true means TYPE_NULL/raw)
timeout 20 termux-x11-preference \
  preferScancodes:"false" \
  enforceCharBasedInput:"false" \
  showIMEWhileExternalConnected:"true" >/dev/null 2>&1 || true
echo ">> switched. ($(wc -l <"$MANIFEST") files linked, no copy)"
