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

scenarios:
	R CMD BATCH --vanilla runner.R runner.Rout &

scenarios-chpc:
	sbatch --partition=notchpeak-freecycle --account=vegayon --cpus-per-task=50 --mem=200G --wrap="Rscript --vanilla runner.R"

module:
	@echo "Ensure to run the following command"
	@echo "module load R/4.4.0 quarto"
