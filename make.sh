#!/bin/sh

# pm i texlive-xetex texlive-lang-cyrillic fonts-cmu
# git clone https://github.com/Cortan122/fasm.git asm
# scp -r ~/dz2020/bio scp://cortan122.tk/~/
# rm !(**/*.png|**/*.fasta)
# rm **/!(*.png|*.fasta)

clean() {
  rm -rf *.log *.aux *.pdf *.toc *.atfi *.ipynb.tex *.out *.pytxcode pandoc_media/
}

[ -n "$1" ] && "$1" && exit

mkdir -p ../latex_pdfs/
for i in *.tex; do
  f="$(basename "$i" .tex)"
  [ "$i" -ot "$f.pdf" ] && continue
  grep -F '\begin{document}' "$i" >/dev/null || continue

  if [ -f "$f.ipynb" ]; then
    if pandoc --list-input-formats | grep ipynb >/dev/null; then
      [ "$f.ipynb" -ot "$f.ipynb.tex" ] || pandoc "$f.ipynb" -o "$f.ipynb.tex" --extract-media=pandoc_media
    else
      jupyter nbconvert --to pdf "$f.ipynb"
      continue
    fi
  fi

  cmd="xelatex"
  grep -F '\usepackage[english,russian]{babel}' "$i" >/dev/null && cmd="pdflatex"

  "$cmd" "$i" || exit 1
  grep 'Rerun to get cross-references right.' "$f.log" && "$cmd" "$i"

  cp "$f.pdf" ../latex_pdfs/"$f.pdf"
  touch -d "$(git log -1 --format="%as" -- "$i")" ../latex_pdfs/"$f.pdf"
done

exit 0
