#!/usr/bin/env bash

get_fonts() {
  local commands=(
    figlet
    toilet
  )

  for cmd in "${commands[@]}"; do
    if ! command -v "$cmd" &> /dev/null; then
      continue
    fi

    cmd_path="$(realpath "$(which "$cmd")")"
    parent_dir="$(dirname "$(dirname "$cmd_path")")"
    font_path="$(realpath "$parent_dir/share")"
    find "$font_path" \
      -type f \
      -name "*.flf" \
      -o -name "*.tlf" |
      sort --version-sort
  done
}

show_font() {
  if [ ! -f ./show_font.sh ]; then
    echo "error: missing show_font.sh"
    exit 1
  fi
  bash show_font.sh "$@"
}

show_interactive() {
  if ! command -v fzf &> /dev/null; then
    echo "error: missing fzf"
    exit 1
  fi

  font_table=()
  for path in "${font_paths[@]}"; do
    font_name="$(basename "${path%.*}")"
    font_table+=("$font_name $path")
  done

  font_format="%-15s %s\n"
  header="$(printf "$font_format" "font name" "path")"
  printf "%s\n" "${font_table[@]}" |
    awk -v format="$font_format" '{printf(format, $1, $2)}' |
    sort --version-sort |
    uniq |
    fzf \
      --height="50%" \
      --multi \
      --info=inline \
      --bind="ctrl-a:toggle-all" \
      --bind="ctrl-d:deselect-all" \
      --bind="ctrl-n:preview-half-page-down" \
      --bind="ctrl-p:preview-half-page-up" \
      --layout=reverse \
      --padding=0 \
      --margin=0 \
      --header="$header" \
      --preview="bash show_font.sh {2} '$message'" \
      --preview-window="bottom" |
    awk '{ print $2 }'
}

show_help() {
  echo "show a sample of all renderable fonts"
  echo "usage: ${BASH_SOURCE[0]} [<option> ...] <message>"
  echo ""
  echo "options:"
  echo "  -h, --help          show this help message and exit"
  echo "  -f, --font=<path>   path to font"
  echo "  -i, --interactive   show interactive font selector"
}

# start script -----------------------------------------------------------------

# begin: options ---------------------------------------------------------------
declare -a font_paths=()
message=""
menu_interactive=0
search_fonts=0

while [[ $# -gt 0 ]]; do
  i="$1"
  case $i in
    -h | --help)
      show_help
      exit 0
      ;;

    -f=* | --font=*)
      opt_path="${i#*=}"
      if [ "$search_fonts" -eq 0 ]; then
        echo "searching for fonts..."
        search_fonts=1
      fi

      if [ -f "$opt_path" ]; then
        font_paths+=("$opt_path")
      else
        echo "error: font not found '$opt_path'"
      fi
      shift
      ;;

    -i | --interactive)
      menu_interactive=1
      shift
      ;;

    *)
      message="$*"
      break
      ;;
  esac
done
# end: options------------------------------------------------------------------

if [ "${#font_paths[@]}" -eq 0 ]; then
  echo "searching for fonts..."
  for path in $(get_fonts); do
    font_paths+=("$path")
  done
fi

if [ "${#font_paths[@]}" -eq 0 ]; then
  echo "error: no figlet/toilet found"
  exit 1
fi

if [ "$menu_interactive" -eq 1 ]; then
  show_interactive "${font_paths[@]}" "$message"
  exit 0
fi

separator="="
for path in "${font_paths[@]}"; do
  show_font "$path" "$message"
  printf "$separator%.0s" {1..100}
  printf '\n'
done
