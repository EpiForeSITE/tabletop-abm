update-data: clean-data clone-data

clone-data:
	git clone -b tabletop-exercise --depth=1 https://github.com/EpiForeSITE/multigroup-vaccine mgv
	cp mgv/vignettes/experiments/tabletop/davis_county_census.Rmd mgv.Rmd
	$(MAKE) clean-data

clean-data:
	rm -rf mgv

data:
	Rscript --vanilla data/davis_population.R