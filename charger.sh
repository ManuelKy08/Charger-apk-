#!/data/data/com.termux/files/usr/bin/bash
tput civis 2>/dev/null
trap 'tput cnorm 2>/dev/null; printf "\033[0m"; clear; exit 0' INT TERM

RST=$'\033[0m'; B=$'\033[1m'
RED=$'\033[31m'; GRN=$'\033[32m'; YEL=$'\033[33m'
CYN=$'\033[36m'; WHT=$'\033[37m'; MAG=$'\033[35m'
DIM=$'\033[2m'

REAL=0
pct=0
PLUGGED=""; HEALTH=""; CURMA=0; TEMP=""; STATUS=""

read_battery() {
  if command -v termux-battery-status >/dev/null 2>&1; then
    local json capf
    json=$(termux-battery-status 2>/dev/null)
    capf=$(printf '%s\n' "$json" | sed -n 's/.*"percentage": *\([0-9]*\).*/\1/p')
    if [ -n "$capf" ]; then
      REAL=1
      pct=$capf
      STATUS=$(printf '%s\n' "$json" | sed -n 's/.*"status": *"\([^"]*\)".*/\1/p')
      HEALTH=$(printf '%s\n' "$json" | sed -n 's/.*"health": *"\([^"]*\)".*/\1/p')
      PLUGGED=$(printf '%s\n' "$json" | sed -n 's/.*"plugged": *"\([^"]*\)".*/\1/p')
      TEMP=$(printf '%s\n' "$json" | sed -n 's/.*"temperature": *\([0-9.]*\).*/\1/p')
      TEMP=${TEMP%.*}
      CURR=$(printf '%s\n' "$json" | sed -n 's/.*"current": *\([-0-9.]*\).*/\1/p')
      CURR=${CURR%.*}
      CURMA=$(( ${CURR:-0} / 1000 ))
      return
    fi
  fi

  local d
  pct=""; STATUS=""; TEMP=""; CURMA=0
  for d in /sys/class/power_supply/*/; do
    [ -f "$d/capacity" ] || continue
    pct=$(cat "$d/capacity" 2>/dev/null)
    [ -n "$pct" ] && break
  done
  if [ -n "$pct" ]; then
    REAL=1
    STATUS=$(cat "${d}status" 2>/dev/null)
    TEMP=$(cat "${d}temp" 2>/dev/null)
    CURMA=$(( $(cat "${d}current_now" 2>/dev/null) / 1000 ))
    TEMP=$(( ${TEMP:-0} / 10 ))
    PLUGGED="?"
    return
  fi

  REAL=0
  STATUS="SIMULASI"
  [ -z "$pct" ] && pct=0
}

gradnum() {
  if   [ "$1" -ge 90 ]; then echo 92
  elif [ "$1" -ge 65 ]; then echo 96
  elif [ "$1" -ge 40 ]; then echo 93
  else                       echo 91
  fi
}
grad() { printf "\033[%dm" "$(gradnum "$1")"; }

repeat_char() { local n=$1 ch=$2 s=""; for ((j=0;j<n;j++)); do s+=$ch; done; printf "%s" "$s"; }

frame() {
  local W=${COLUMNS:-42}
  local barW=$(( W - 12 ))
  [ "$barW" -lt 15 ] && barW=15
  local fill=$(( pct * barW / 100 ))
  [ "$fill" -gt "$barW" ] && fill=$barW
  local c
  c=$(grad "$pct")

  printf "\033[2J\033[H"
  local title="S U P E R   C H A R G E  ⚡"
  local inner=$(( W - 8 ))
  local tlen=${#title}
  local lpad=$(( (inner - tlen) / 2 ))
  local rpad=$(( inner - tlen - lpad ))
  printf "  ${CYN}╔"
  printf "%s" "$(repeat_char $((W - 6)) ═)"
  printf "╗${RST}\n"
  printf "  ${CYN}║${RST}${B}%*s%s%-*s${RST}${CYN}║${RST}\n" "$lpad" "" "$title" "$rpad" ""
  printf "  ${CYN}╚"
  printf "%s" "$(repeat_char $((W - 6)) ═)"
  printf "╝${RST}\n"

  printf "\n"

  # battery graphic
  # battery graphic
  printf "  ${WHT}┌"
  printf "%s" "$(repeat_char $((barW)) ─)"
  printf "┐▕${RST}\n"
  printf "  ${WHT}│${RST} "
  for ((i = 0; i < barW; i++)); do
    if [ "$i" -lt "$fill" ]; then
      printf "${B}${c}█${RST}"
    else
      printf "\033[2m░${RST}"
    fi
  done
  printf "${WHT} │▕${RST}\n"
  printf "  ${WHT}└"
  printf "%s" "$(repeat_char $((barW)) ─)"
  printf "┘▕${RST}\n"

  printf "\n"
  local pctp="${pct}%"
  local plen=${#pctp}
  inner=$(( W - 8 ))
  lpad=$(( (inner - plen - 26) / 2 ))
  rpad=$(( inner - plen - 26 - lpad ))
  [ "$lpad" -lt 0 ] && lpad=0; [ "$rpad" -lt 0 ] && rpad=0
  printf "  ${B}%*s${c}%s${RST}%*s${DIM}kapasitas ${B}%4d mAh${RST}\n" "$lpad" "" "$pctp" "$rpad" "" "$(( pct * 4000 / 100 ))"
  printf "\n"

  # status banner
  if [ "$REAL" -eq 1 ]; then
    local ilabel icolor itxt
    case "$STATUS" in
      *DISCHARG*)  icon="⚠"; icolor=$RED; itxt="G A B U S  N G E - C H A R G E";;
      *NOT*|"")    icon="⚠"; icolor=$RED; itxt="G A B U S  N G E - C H A R G E";;
      *FULL*)      icon="✓"; icolor=$GRN; itxt="B A T E R A I  P E N U H";;
      *CHARGING*)  icon="⚡"; icolor=$GRN; itxt="S E D A N G  N G E - C H A R G E";;
    esac
    inner=$(( W - 8 ))
    lpad=$(( (inner - ${#itxt} - 4) / 2 ))
    printf "  ${CYN}╭─"
    printf "%s" "$(repeat_char $((W - 8)) ─)"
    printf "─╮${RST}\n"
    printf "  ${CYN}│${RST}${B}${icolor} %s${RST}  ${B}${icolor}${itxt}${RST}\n" "$icon"
    printf "  ${CYN}╰─"
    printf "%s" "$(repeat_char $((W - 8)) ─)"
    printf "─╯${RST}\n"
    printf "\n"

    case "$PLUGGED" in
      PLUGGED_AC|AC)   KABELTXT="${GRN}AC (kabel)${RST}";;
      USB)             KABELTXT="${GRN}USB${RST}";;
      WIRELESS)        KABELTXT="${GRN}wireless${RST}";;
      UNPLUGGED)       KABELTXT="${RED}belum dicolok${RST}";;
      *)               KABELTXT="${GRN}${PLUGGED:-?}${RST}";;
    esac

    printf "   ${WHT}│ STATUS     │${RST} ${B}${YEL}%s${RST}\n" "${STATUS:-?}"
    printf "   ${WHT}│ KABEL      │${RST} ${B}${KABELTXT}${RST}\n"
    printf "   ${WHT}│ ARUS       │${RST} ${B}${MAG}%+d mA${RST} ${DIM}(minus = kepake, plus = nge-charge)${RST}\n" "${CURMA:-0}"
    printf "   ${WHT}│ SUHU       │${RST} ${B}${RED}%s°C${RST}\n" "${TEMP:-?}"
    printf "   ${WHT}│ KESEHATAN  │${RST} ${B}${GRN}%s${RST}\n" "${HEALTH:-?}"
    printf "\n"
  else
    printf "  ${CYN}╭─"
    printf "%s" "$(repeat_char $((W - 8)) ─)"
    printf "─╮${RST}\n"
    printf "  ${CYN}│${RST}${B}${MAG}${DIM}%*s${RST}${B}${MAG}  ⚠  MODE  SIMULASI${RST}\n" "$((W - 29))" ""
    printf "  ${CYN}╰─"
    printf "%s" "$(repeat_char $((W - 8)) ─)"
    printf "─╯${RST}\n"
    printf "\n"
    printf "  ${DIM}  Gak kebaca datanya, jadi ini pala persen bikin-bikinan.${RST}\n"
    printf "  ${DIM}  Install 'pkg install termux-api' biar kebaca data asli.${RST}\n"
    printf "\n"
  fi

  # bottom hint
  printf "   ${DIM}· refresh tiap 1.5 detik · Ctrl+C berhenti ·${RST}\n"
  printf "   ${WHT}· ${B}${CYN}powered by Risky Manuel T${RST}${WHT} ·${RST}\n"
}

start=$SECONDS
read_battery

while :; do
  read_battery
  frame
  sleep 1.5
done