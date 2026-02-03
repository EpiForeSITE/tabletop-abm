update-data: clean-data clone-data

clone-data:
	git clone -b tabletop-exercise --depth=1 https://github.com/EpiForeSITE/multigroup-vaccine mgv
	cp mgv/vignettes/experiments/tabletop/davis_county_census.Rmd mgv.Rmd
	$(MAKE) clean-data

clean-data:
	rm -rf mgv

data:
	Rscript --vanilla data/davis_population.R

install:
	Rscript --vanilla -e 'devtools::install_github("UofUEpiBio/epiworldR@gvegayon/tabletop")'

README.md: README.qmd
	quarto render README.qmd

allocate:
	salloc --partition=notchpeak-freecycle --account=vegayon -c50 --mem=200G