#!/bin/bash

mapfile -t filenames1 < <(grep -rFl -f names.txt | grep -v names.txt | grep -v '.*.ipynb$')
mapfile -t filenames < <(grep -LF '\AA' "${filenames1[@]}")

if [ "${#filenames[@]}" == 0 ]; then
  echo "no files to change..."
  exit
fi
echo "changing ${#filenames[@]} files..."

res=""
i=1
while read -r name; do
  sed -i "s/$name/\\\\AA{$name}{$i}/g" "${filenames[@]}"
  res="$res\\or $name"
  i=$((i + 1))
done <names.txt

printf '\\renewcommand{\\AA}[2]{\\ifcase#2 %s\\else#1\\fi}\n' "$res" > replaced_names.sty
