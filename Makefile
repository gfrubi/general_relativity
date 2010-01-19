RUN_ERUBY = perl -Iscripts scripts/run_eruby.pl

DO_PDFLATEX_RAW = pdflatex -shell-escape -interaction=nonstopmode genrel >err
# -shell-escape is so that write18 will be allowed
SHOW_ERRORS = \
        print "========error========\n"; \
        open(F,"err"); \
        while ($$line = <F>) { \
          if ($$line=~m/^\! / || $$line=~m/^l.\d+ /) { \
            print $$line \
          } \
        } \
        close F; \
        exit(1)
DO_PDFLATEX = echo "$(DO_PDFLATEX_RAW)" ; perl -e 'if (system("$(DO_PDFLATEX_RAW)")) {$(SHOW_ERRORS)}'

default:
	@make preflight
	$(RUN_ERUBY)
	# perl -e 'foreach $$f(<ch*>) {if (-d $$f) {$$f=~/ch(\d\d)/; $$n=$$1; $$c = "cd ch$$n && ../fruby ch$$n.rbtex >ch$${n}temp.tex && cd -"; print "$$c\n"; system $$c}}'
	$(DO_PDFLATEX)
	@process_geom_file.pl <geom.pos >temp.pos
	@mv temp.pos geom.pos
	makeindex genrel.idx >/dev/null

book:
	make clean
	make && make
	@scripts/check_for_colliding_figures.rb
	@scripts/harvest_aux_files.rb
	make

web:
	WOPT='$(WOPT) --modern' $(RUN_ERUBY) w #... xhtml
	$(RUN_ERUBY) w                         #... html
	# To set options, do, e.g., "WOPT='--no_write' make web". Options are documented in translate_to_html.rb.

clean:
	# Cleaning...
	@rm -f genrel.pdf genrel_lulu.pdf
	@rm -f temp.tex
	@rm -f ch*/ch*temp.tex 
	@rm -f bk*lulu.pdf simple1.pdf simple2.pdf # lulu files
	@rm -f ch*.pos geom.pos report.pos marg.pos makefilepreamble
	@rm -f figfeedback*
	@rm -f ch*/ch*temp_new ch*/*.postm4 ch*/*.wiki
	@rm -f code_listing_* code_listings/* code_listings.zip
	@rm -Rf code_listings
	@# Sometimes we get into a state where LaTeX is unhappy, and erasing these cures it:
	@rm -f *aux *idx *ilg *ind *log *toc
	@rm -f ch*/*aux
	@# Shouldn't exist in subdirectories:
	@rm -f */*.log
	@# Emacs backup files:
	@rm -f *~
	@rm -f */*~
	@rm -f */*/*~
	@rm -f */ch*.temp
	@# Misc:
	@rm -Rf ch*/figs/.xvpics
	@rm -f a.a
	@rm -f */a.a
	@rm -f */*/a.a
	@rm -f junk
	@rm -f err
	@rm -f temp_mathml.html temp_mathml.tex temp.html
	@# ... done.

preflight:
	@perl -e 'foreach $$f("scripts/run_eruby.pl","scripts/equation_to_image.pl","scripts/latex_table_to_html.pl","scripts/harvest_aux_files.rb","scripts/check_for_colliding_figures.rb","scripts/translate_to_html.rb","mv_silent") {die "file $$f is not executable; fix this with chmod +x $$f" unless -e $$f && -x $$f}'

post:
	cp genrel.pdf ~/Lightandmatter/genrel

prepress:
	pdftk genrel.pdf cat 3-end output temp.pdf
	# The following makes Lulu not complain about missing fonts. Make sure the version of gs is recent enough so that it won't mess up
	# ligatures in Helvetica. Also, lulu sometimes chokes if gs version is <8.x.
	gs -q  -dCompatibilityLevel=1.4 -dSubsetFonts=false -dPDFSETTINGS=/printer -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -sOutputFile=genrel_lulu.pdf temp.pdf -c '.setpdfwrite'
	@rm -f temp.pdf

all_figures:
	# The following requires Inkscape 0.47 or later.
	perl -e 'foreach my $$f(<*/ch*/figs/*.svg>) {$$g=$$f; $$g=~s/\.svg$$/.pdf/; print "g=$$g\n"; $$c="inkscape --export-text-to-path --export-pdf=$$g $$f  --export-area-drawing"; print "$$c\n"; system($$c)}'
