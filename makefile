TMP ?= tmp
current_dir = $(shell pwd)

.ONESHELL:

mp := -p
cp := cp
ifeq ($(OS),Windows_NT)
cp := copy
mp :=
endif

all: derivatives.png derivativesOnly.png integrals.png

%.tex: %_if.tex
	sed "s/^\x25#/#/" $< | cpp ${ARGS} -x c - -o - | sed "s/^#.*$$//" > $@

%.pdf: %.tex
	latexmk.py -c $<

%-crop.pdf: %.pdf
	pdfcrop --margins 10 $< $@

%.png: %-crop.pdf
	pdftoppm $< -r 600 -png -singlefile > $@
	magick mogrify $@

матан\ hw2.pdf: матан\ hw2.tex
	mkdir $(mp) $(TMP)
ifeq ($(OS),Windows_NT)
	copy "$^" $(TEMP)\matan_hw2.tex
	mv $(TEMP)\matan_hw2.tex $(TMP)
else
	cp "$^" $(TMP)
endif
	cp *.sty $(TMP)
	cd $(TMP)
ifeq ($(OS),Windows_NT)
	move matan_hw2.tex "$^"
endif
	pdflatex.exe --synctex=1 --file-line-error --shell-escape --interaction=nonstopmode "$^"
	pythontex.exe "$^"
	pdflatex.exe --synctex=1 --file-line-error --shell-escape --interaction=nonstopmode "$^"
	$(cp) "$@" $(current_dir)

clean:
	rm -f *.png

.PHONY: all clean
.INTERMEDIATE: %.tex
