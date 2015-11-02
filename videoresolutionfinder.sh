#!/bin/bash

#Finds all video files with a resolution
#Copyright © 2015 Matthias Johannes Reimchen

#This program is free software: you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation, either version 3 of the License, or
#any later version.

#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.

#You should have received a copy of the GNU General Public License
#along with this program.  If not, see <http://www.gnu.org/licenses/>.


#Constants
declare -ir LESSSTRATEGY=0
declare -ir LESSEQUALSTRATEGY=1
declare -ir GREATEREQUALSTRATEGY=2
declare -ir GREATERSTRATEGY=3
declare -ir EQUALSTRATEGY=4

DIRECTORY=$(pwd)
declare -i X_RES
declare -i Y_RES
declare -i STRATEGY=$LESSEQUALSTRATEGY

help() {
  printf "%s\n" "Usage: $0 [OPTION]... [FILE]..."
  printf "%s%s\n" "Recursively removes all video files in a directory with "\
    "certain resolutions."
  printf "\t%s\t%s\n" "-h, --help" "display this help and exit"
  printf "\t%s\t%s\n" "-x, --xRes" "the width resolution of the video"
  printf "\t%s\t%s\n" "-y, --yRes" "the height resolution of the video"
  printf "\t%s\t%s\n" "-s, --strategy STRATEGY" "the removal strategy"
  printf "\n\t%s\n" "STATEGIES"
  printf "\t%s%s\n" "A STRATEGY determines which video files to delete depending on the "\
                  "specified width and height resolutions."
  printf "\t%s\n" "lt is the default strategy."
  printf "\t%s\t%s\n" "less" "removes all video files with lower resolution."
  printf "\t%s\t%s\n" "lt" "removes all video files with lower or equal resolution."
  printf "\t%s\t%s\n" "greater" "removes all video files with greater resolution."
  printf "\t%s\t%s\n" "gt" "removes all video files with greater or equal resolution."
  printf "\t%s\t%s\n" "eq" "removes all video files with equal resolution."
}

init() {
  while [[ "$1" == -* ]]; do
    case "$1" in
      "--help"|"-h" )
        help;
        exit 0
        ;;
      "--xRes"|"-x" )
        X_RES=$2
        shift
        ;;
      "--yRes"|"-y" )
        Y_RES=$2
        shift
        ;;
      "--strategy"|"-s" )
        case "$2" in
          "less" )
            STRATEGY=$LESSSTRATEGY
            ;;
          "lt" )
            STRATEGY=$LESSEQUALSTRATEGY
            ;;
          "greater" )
            STRATEGY=$GREATERSTRATEGY
            ;;
          "gt" )
            STRATEGY=$GREATEREQUALSTRATEGY
            ;;
          "eq" )
            STRATEGY=$EQUALSTRATEGY
            ;;
          *)
            echo "$0: invalid option '$2'" >&2
            help
            exit 1
            ;;
        esac
        shift
        ;;
      *)
        echo "$0: invalid option '$1'" >&2
        help
        exit 1
        ;;
    esac
    shift
  done
  DIRECTORY="$1"
}

hit() {
  echo $1
}

search() {
  while read line; do
    local -i xRes=$(ffprobe "-v" "-8" "-of" "default=nk=1:nw=1"\
      "-show_entries" "stream='width'"\
      "-select_streams" "v" "$line")
    if (( $? != 0 )); then
      continue
    fi
    local -i yRes=$(ffprobe "-v" "-8" "-of" "default=nk=1:nw=1"\
      "-show_entries" "stream='height'"\
      "-select_streams" "v" "$line")
    if (( $? != 0 )); then
      continue
    fi
    case $STRATEGY in
      $LESSSTRATEGY)
        if (( xRes < X_RES && yRes < Y_RES )); then
          hit "$line"
        fi
        ;;
      $LESSEQUALSTRATEGY)
        if (( xRes <= X_RES && yRes <= Y_RES )); then
          hit "$line"
        fi
        ;;
      $GREATEREQUALSTRATEGY)
        if (( xRes > X_RES && yRes > Y_RES )); then
          hit "$line"
        fi
        ;;
      $GREATERSTRATEGY)
        if (( xRes >= X_RES && yRes >= Y_RES )); then
          hit "$line"
        fi
        ;;
      $EQUALSTRATEGY)
        if (( xRes == X_RES && yRes == Y_RES )); then
          hit "$line"
        fi
        ;;
      *)
        echo "Invalid strategy!" >&2
        exit 10
        ;;
    esac

  done < <(find "$DIRECTORY" "-type" "f" "-name" "*.flv")
}

init "$@"
search

