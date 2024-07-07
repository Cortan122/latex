#!/bin/bash

mapfile -t filenames < <(grep -rFl -f names.txt)

res=""
i=1
while read -r name; do
  sed -i "s/$name/\\\\AA{$name}{$i}/g" "${filenames[@]}"
  res="$res\\or $name"
  i=$((i + 1))
done <names.txt

printf '\\renewcommand{\\AA}[2]{\\ifcase#2 %s\\else#1\\fi}\n' "$res" > replaced_names.sty
