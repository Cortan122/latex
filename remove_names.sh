#!/bin/bash

# this script automatically looks at which files actually need to be changed
# it is smart like that
# i can just run it before committing new files

mapfile -t filenames1 < <(grep -rFl -f names.txt | grep -v names.txt | grep -v '.*.ipynb$')
if [ "${#filenames1[@]}" != 0 ]; then
  mapfile -t filenames < <(grep -LF '\AA' "${filenames1[@]}")
fi

if [ "${#filenames[@]}" == 0 ]; then
  echo "no files to change..."
else
  echo "changing ${#filenames[@]} files..."
fi

res=""
i=1
while read -r name; do
  if [ "${#filenames[@]}" != 0 ]; then
    sed -i "s/$name/\\\\AA{$name}{$i}/g" "${filenames[@]}"
  fi
  res="$res\\or $name"
  i=$((i + 1))
done <names.txt

printf '\\renewcommand{\\AA}[2]{\\ifcase#2 %s\\else#1\\fi}\n' "$res" > replaced_names.sty
