#!/usr/bin/env bash
set -euo pipefail

vr=0
fast=0
dry_run=0
world=""
for arg in "$@"; do
    case "$arg" in
        --fast) fast=1 ;;
        --dry-run) dry_run=1 ;;
        *) world="$arg" ;;
    esac
done

find_world() {
    local input="$1"
    if [[ -f "$input" && "$input" == *.vrcw ]]; then
        realpath "$input"
        return
    fi
    [[ -d "$input" ]] || return 1
    find "$input" -type f -name '*.vrcw' -print -quit
}

if [[ -z "$world" ]]; then
    read -r -p 'Drop a .vrcw file or folder here (blank = search current directory): ' world
    world="${world:-.}"
fi

while true; do
    world="${world%\"}"
    world="${world#\"}"
    found_world="$(find_world "$world" || true)"
    if [[ -n "$found_world" ]]; then
        world="$found_world"
        break
    fi
    printf 'No .vrcw file found at: %s\n' "$world" >&2
    read -r -p 'Drop a .vrcw file or folder here (blank = search current directory): ' world
    world="${world:-.}"
done

steam_roots=(
    "$HOME/.steam/root"
    "$HOME/.steam/steam"
    "$HOME/.local/share/Steam"
    "$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam"
)

steam_root=""
libraries=()
for root in "${steam_roots[@]}"; do
    [[ -d "$root/steamapps" ]] || continue
    [[ -n "$steam_root" ]] || steam_root="$(realpath "$root")"
    libraries+=("$root")
    vdf="$root/steamapps/libraryfolders.vdf"
    if [[ -f "$vdf" ]]; then
        while IFS= read -r library; do libraries+=("$library"); done < <(
            awk -F'"' '/^[[:space:]]*"path"/ { gsub(/\\\\/, "\\", $4); print $4 }' "$vdf"
        )
    fi
done

vrchat="${VRCHAT_PATH:-}"
if [[ -d "$vrchat" ]]; then vrchat="$vrchat/launch.exe"; fi
if [[ ! -f "$vrchat" ]]; then
    vrchat=""
    for library in "${libraries[@]}"; do
        for exe in launch.exe VRChat.exe; do
            candidate="$library/steamapps/common/VRChat/$exe"
            if [[ -f "$candidate" ]]; then vrchat="$candidate"; break 2; fi
        done
    done
fi
while [[ ! -f "$vrchat" ]]; do
    read -r -p 'VRChat was not found. Drop its folder or launch.exe here: ' vrchat
    vrchat="${vrchat%\"}"; vrchat="${vrchat#\"}"
    [[ -d "$vrchat" ]] && vrchat="$vrchat/launch.exe"
done

proton="${PROTON_PATH:-}"
if [[ ! -x "$proton" ]]; then
    proton=""
    for root in "${steam_roots[@]}"; do
        candidates=(
            "$root/steamapps/common/Proton - Experimental/proton"
            "$root/steamapps/common"/Proton*/proton
            "$root/compatibilitytools.d"/*/proton
        )
        for candidate in "${candidates[@]}"; do
            if [[ -x "$candidate" ]]; then proton="$candidate"; break 2; fi
        done
    done
fi
while [[ ! -x "$proton" ]]; do
    read -r -p 'Proton was not found. Drop its proton file here: ' proton
    proton="${proton%\"}"; proton="${proton#\"}"
done

room_id="$(printf '%d' "$((1 + RANDOM % 9))")"
for _ in {1..9}; do room_id+="$((RANDOM % 10))"; done
if (( fast )); then
    clients=1
else
    read -r -p 'Client count (default 1): ' clients
    clients="${clients:-1}"
    [[ "$clients" =~ ^[1-9][0-9]*$ ]] || { echo 'Client count must be a positive number.' >&2; exit 1; }

    read -r -p 'Launch in VR mode? (y/N): ' mode
    case "${mode,,}" in
        y|yes) vr=1 ;;
        ""|n|no) vr=0 ;;
        *) echo 'Please answer y or n.' >&2; exit 1 ;;
    esac
fi

world="$(realpath "$world")"
world_uri="file://$world"
world_uri="${world_uri//%/%25}"
world_uri="${world_uri// /%20}"
world_uri="${world_uri//#/%23}"
args=(
    "--url=create?roomId=$room_id&hidden=true&name=BuildAndRun&url=$world_uri"
    --enable-debug-gui --enable-sdk-log-levels --enable-udon-debug-logging --watch-worlds
)
(( vr )) || args+=(--no-vr)

compat_data="${STEAM_COMPAT_DATA_PATH:-}"
if [[ -z "$compat_data" ]]; then
    compat_data="$steam_root/steamapps/compatdata/438100"
    for library in "${libraries[@]}"; do
        if [[ "$vrchat" == "$library/"* ]]; then
            compat_data="$library/steamapps/compatdata/438100"
            break
        fi
    done
fi
export STEAM_COMPAT_CLIENT_INSTALL_PATH="$steam_root"
export STEAM_COMPAT_DATA_PATH="$compat_data"

mode_name="Desktop"
if (( vr )); then mode_name="VR"; fi
printf 'World  : %s\nVRChat : %s\nProton : %s\nRoom   : %s (random)\nClients: %s\nMode   : %s\n' \
    "$world" "$vrchat" "$proton" "$room_id" "$clients" "$mode_name"
for ((i = 1; i <= clients; i++)); do
    if (( dry_run )); then
        printf 'DRY RUN:'; printf ' %q' "$proton" runinprefix "$vrchat" "${args[@]}"; printf '\n'
    else
        "$proton" runinprefix "$vrchat" "${args[@]}" &
    fi
done
