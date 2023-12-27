#!/usr/bin/env bash

error_log="$(basename "${BASH_SOURCE[0]}").error.log"

font_path="$1"
font_name="$(basename "${font_path%.*}")"

message="${2:-$font_name}"

if command -v toilet &> /dev/null; then
  font_dir="$(dirname "$font_path")"
  cmd="toilet \
    --font '$font_name' \
    --directory '$font_dir' \
    --filter crop \
    '$message'"
fi

# On Ubuntu, `update-alternatives` is a tool used to switch between two
# programs, `figlet` and `toilet`. When `toilet` is installed and `figlet` *is
# not*, `toilet` creates a `figlet`[1] binary that causes a false positive when
# using `command -v figlet`. See the table below shows the different
# combinations and the binaries that are created at install.
#
# This causes a few issues:
#   1. We use the binary location (`which <cmd>`) to derive the `share` path
#      (e.g. `/usr/share/figlet`) to aggregate all fonts. A false positive
#      breaks since it resolves to the wrong `share` path
#
#   2. `figlet` as our default renderer since it supports more fonts and both
#       load fonts differently than the other.
#
#       Note: `toilet` has more features such as cropping, width, and color
#       so it's possible to find a font that won't be loaded.
#
#   3. `figlet-figlet` is only on Ubuntu so avoiding OS checks whenever
#   possible improves maintenance and portability
#
# To address this we use `figlist` which is a `figlet` exclusive binary. Now
# we're able to dynamically list all installed fonts to have a better idea of
# what the our text will look like.
#
# +-------------------+-------------------+----------------------------------------------------+
# | toilet installed  | figlet installed  | binaries                                           |
# +-------------------+-------------------+----------------------------------------------------+
# |        no         |        no         |                                                    |
# |        yes        |        no         | figlet[1], figlet-toilet[2], toilet                |
# |        no         |        yes        | figlet, figlet-figlet[2]                           |
# |        yes        |        yes        | figlet, figlet-figlet[2], figlet-toilet[2], toilet |
# +-------------------+-------------------+----------------------------------------------------+
# [1] not really `figlet` but `toilet`
# [2] only on ubuntu
if command -v figlist &> /dev/null; then
  # we default to `figlet` because it supports the rendering of more fonts
  cmd="figlet -f '$font_path' '$message'"
fi

if [ -z "$cmd" ]; then
  current_date="$(date +'%FT%T')"
  echo "[$current_date] ERROR - unable to find 'figlet' or 'toilet'" | tee -a "$error_log"
  exit 1
fi

# toilet can't render some fonts, which is the main reason we see these errors.
# this may also happen when the `find` filters are modified. we `eval` twice to
# improve output readability (suppressing font/path fields) as well as
# persisting to an error log.
if ! eval "$cmd" > /dev/null 2>&1; then
  current_date="$(date +'%FT%T')"
  echo "[$current_date] ERROR - unable to render '$font_path'" | tee -a "$error_log"
  exit 1
fi

printf "font: %s\n" "$font_name"
echo "path: $font_path"
eval "$cmd"
