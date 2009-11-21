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

clean:
	# Cleaning...
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
	@# ... done.

preflight:
	@perl -e 'foreach $$f("scripts/run_eruby.pl","mv_silent") {die "file $$f is not executable; fix this with chmod +x $$f" unless -e $$f && -x $$f}'
