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

clean:
	rm -f *.png

.PHONY: all clean
.INTERMEDIATE: %.tex
