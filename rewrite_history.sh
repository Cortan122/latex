#!/bin/bash

while read -r name; do
  nameA="${name//[^ ]/A}"
  printf '%s==>%s\n' "$name" "$nameA"
done <names.txt | git filter-repo --replace-text /dev/stdin
