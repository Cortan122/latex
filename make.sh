#!/bin/sh

# pm i texlive-xetex texlive-lang-cyrillic fonts-cmu texlive-bibtex-extra
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
  grep -Fq '\begin{document}' "$i" || continue

  if [ -f "$f.ipynb" ]; then
    if pandoc --list-input-formats | grep -Fq ipynb; then
      [ "$f.ipynb" -ot "$f.ipynb.tex" ] || pandoc "$f.ipynb" -o "$f.ipynb.tex" --extract-media=pandoc_media
    else
      jupyter nbconvert --to pdf "$f.ipynb"
      continue
    fi
  fi

  cmd="xelatex"
  grep -Fq '\usepackage[english,russian]{babel}' "$i" && cmd="pdflatex"

  "$cmd" "$i" || exit 1
  grep -Fq 'Rerun to get cross-references right.' "$f.log" && "$cmd" "$i"

  if grep -Fq 'There were undefined references.' "$f.log"; then
    bibtex "$f" || exit 1
    "$cmd" "$i" || exit 1
    "$cmd" "$i" || exit 1
  fi

  cp "$f.pdf" ../latex_pdfs/"$f.pdf"
  touch -d "$(git log --format="%ai" -- "$i" | tail -n -1)" ../latex_pdfs/"$f.pdf"
done

exit 0