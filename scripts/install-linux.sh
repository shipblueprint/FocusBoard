#!/usr/bin/env bash
# Install (or update) the Linux build for the current user. No root required.
#
#   scripts/install-linux.sh            # install build/linux/x64/release/bundle
#   scripts/install-linux.sh --debug    # install the debug bundle instead
#   scripts/install-linux.sh --launch   # start it when done
#
# Everything lands under $HOME/.local: the bundle in share/focusboard, the menu
# entry in share/applications, icons in share/icons/hicolor.
set -euo pipefail

root="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"
app_id="io.github.shipblueprint.focusboard"
dest="$HOME/.local/share/focusboard"
desktop="$HOME/.local/share/applications/$app_id.desktop"
icon_src="$root/focusboard_icon.png"
variant=release
launch=0

for arg in "$@"; do
  case "$arg" in
    --debug) variant=debug ;;
    --launch) launch=1 ;;
    *) echo "unknown option: $arg" >&2; exit 2 ;;
  esac
done

bundle="$root/build/linux/x64/$variant/bundle"
[ -x "$bundle/FocusBoard" ] || {
  echo "no $variant bundle at $bundle — run flutter build linux --$variant first" >&2
  exit 1
}

# A stale bundle is the failure mode this script exists to prevent: the runner
# binary is not relinked by Dart-only changes, so libapp.so is what matters.
newest_src=$(find "$root/lib" -name '*.dart' -newer "$bundle/lib/libapp.so" -print -quit)
if [ -n "$newest_src" ]; then
  echo "warning: $newest_src is newer than the bundle; it may not contain the current code" >&2
fi

if pgrep -x FocusBoard >/dev/null; then
  echo "stopping the running instance"
  pkill -x FocusBoard
  sleep 1
fi

echo "installing $bundle -> $dest"
mkdir -p "$dest"
rsync -a --delete "$bundle/" "$dest/"

echo "writing $desktop"
mkdir -p "$(dirname "$desktop")"
cat > "$desktop" <<EOF
[Desktop Entry]
Type=Application
Name=FocusBoard
GenericName=Task Board
Comment=Kanban board, Eisenhower matrix, analytics and habit tracker
Exec=$dest/FocusBoard %U
Icon=$app_id
Terminal=false
Categories=Office;ProjectManagement;
Keywords=kanban;tasks;todo;habits;productivity;focus;eisenhower;
StartupWMClass=$app_id
EOF

if [ -f "$icon_src" ]; then
  echo "installing icons from $(basename "$icon_src")"
  for size in 16 24 32 48 64 128 256 512; do
    dir="$HOME/.local/share/icons/hicolor/${size}x${size}/apps"
    mkdir -p "$dir"
    magick "$icon_src" -resize "${size}x${size}" "$dir/$app_id.png"
  done
  command -v gtk-update-icon-cache >/dev/null &&
    gtk-update-icon-cache -q "$HOME/.local/share/icons/hicolor" || true
fi

command -v desktop-file-validate >/dev/null && desktop-file-validate "$desktop"
command -v update-desktop-database >/dev/null &&
  update-desktop-database "$HOME/.local/share/applications" || true

echo "installed: $dest/FocusBoard"
ls -l "$dest/lib/libapp.so"

if [ "$launch" = 1 ]; then
  setsid nohup "$dest/FocusBoard" >/tmp/focusboard.log 2>&1 </dev/null &
  disown
  echo "launched (log: /tmp/focusboard.log)"
fi
