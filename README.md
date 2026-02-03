
``` r
library(epiworldR)
```

    Thank you for using epiworldR! Please consider citing it in your work.
    You can find the citation information by running
      citation("epiworldR")

``` r
library(data.table)
```

## Data preparation

Setting up an empty model for the moment, we will be using the data from
the davis county:

``` r
davis_pop <- fread("data/davis_population.csv")
davis_pop
```

         age_labels agepops agelims vacc_rate
             <char>   <int>   <int>     <int>
      1:     under1    4600       1         0
      2:       1to4   19840       4         0
      3:    5to11s1     673      11         0
      4:    5to11s2     360      11         0
      5:    5to11s3     626      11         0
     ---                                     
    138:  5to11s136     867      11         0
    139:     18to24   37273      24         0
    140:     25to44  108580      44         0
    141:     45to69   95226      69         0
    142:        70+   29039      90         0

Looking into the data

``` r
plot(
  davis_pop$agepops,
  x = davis_pop$agelims,
  xlab = "Age groups",
  ylab = "Population counts",
  main = "Davis County Population by Age Groups"
)
```

![](README_files/figure-commonmark/unnamed-chunk-2-1.png)

``` r
N <- sum(davis_pop$agepops)
```

We can take a look at the mixing matrix

``` r
davis_mixing_matrix <- readRDS("data/davis_mixing_matrix.rds")
image(
  davis_mixing_matrix,
  xlab = "Age groups",
  ylab = "Age groups",
  main = "Davis County Mixing Matrix"
)
```

![](README_files/figure-commonmark/unnamed-chunk-3-1.png)

The image shows a big diagonal in the middle which is expected as
school-age individuals will contact mostly with their peers (most of the
groups we have are schools).

## Model creating

Se will be assuming two values

- Incubation period is 2 to 5 days.
- Basic reproductive number will be between 1.5 and 3.

To compute the basic reproductive number, we use the following:

``` r
R0 <- 2.5
p_transmission <- 0.2
p_recovery <- 1/7
contact_rate <- R0 * p_recovery / p_transmission
```

``` r
davis_model <- ModelSEIRMixingQuarantine(
  name                         = "Davis county",
  n                            = N,
  prevalence                   = 10/N,
  contact_rate                 = contact_rate,
  transmission_rate            = p_transmission,
  incubation_days              = 7,
  recovery_rate                = 1/p_recovery,
  contact_matrix               = davis_mixing_matrix,
  hospitalization_rate         = 0.1,
  hospitalization_period       = 4,
  days_undetected              = 3, 
  quarantine_period            = 14,
  quarantine_willingness       = 1.0,
  isolation_willingness        = 1.0,
  isolation_period             = 5,
  contact_tracing_success_rate = 0.8,
  contact_tracing_days_prior   = 7
)
```

We now start adding some of the entities from the population data:

``` r
add_entities_from_dataframe(
  model = davis_model,
  entities = davis_pop,
  col_name = "age_labels",
  col_number = "agepops",
  as_proportion = FALSE
)
```

Running the model

``` r
davis_model |>
  run_multiple(
    ndays = 100,
    nsims = 50,
    seed  = 8812,
    saver = make_saver("outbreak_size", "hospitalizations"),
    nthreads = 10L
  )
```

    Starting multiple runs (50) using 10 thread(s)
    _________________________________________________________________________
    _________________________________________________________________________
    ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| done.

Looking at the single simulation results

``` r
summary(davis_model)
```

    ________________________________________________________________________________
    ________________________________________________________________________________
    SIMULATION STUDY

    Name of the model   : SEIR with Mixing and Quarantine
    Population size     : 378472
    Agents' data        : (none)
    Number of entities  : 142
    Days (duration)     : 100 (of 100)
    Number of viruses   : 1
    Last run elapsed t  : 0.00m
    Total elapsed t     : 2.00m (50 runs)
    Last run speed      : 2.11 million agents x day / second
    Average run speed   : 13.90 million agents x day / second
    Rewiring            : off

    Global events:
     - Update infected individuals (runs daily)

    Virus(es):
     - Davis county

    Tool(s):
     (none)

    Model parameters:
     - Avg. Incubation days         : 7.0000
     - Contact rate                 : 1.7857
     - Contact tracing days prior   : 7.0000
     - Contact tracing success rate : 0.8000
     - Days undetected              : 3.0000
     - Hospitalization period       : 4.0000
     - Hospitalization rate         : 0.1000
     - Isolation period             : 5.0000
     - Isolation willingness        : 1.0000
     - Prob. Recovery               : 7.0000
     - Prob. Transmission           : 0.2000
     - Quarantine period            : 14.0000
     - Quarantine willingness       : 1.0000

    Distribution of the population at time 100:
      - ( 0) Susceptible             : 378462 -> 378455
      - ( 1) Exposed                 :     10 -> 0
      - ( 2) Infected                :      0 -> 0
      - ( 3) Isolated                :      0 -> 0
      - ( 4) Detected Hospitalized   :      0 -> 0
      - ( 5) Quarantined Susceptible :      0 -> 0
      - ( 6) Quarantined Exposed     :      0 -> 0
      - ( 7) Isolated Recovered      :      0 -> 0
      - ( 8) Hospitalized            :      0 -> 0
      - ( 9) Recovered               :      0 -> 17

    Transition Probabilities:
     - Susceptible              1.00  0.00     -     -     -  0.00  0.00     -     -     -
     - Exposed                     -  0.81  0.19     -     -     -     -     -     -     -
     - Infected                    -     -     -     -     -     -     -  0.38     -  0.62
     - Isolated                    -     -     -     -     -     -     -  1.00     -     -
     - Detected Hospitalized       -     -     -     -     -     -     -     -     -     -
     - Quarantined Susceptible  0.07     -     -     -     -  0.93     -     -     -     -
     - Quarantined Exposed         -     -     -  0.12     -     -  0.88     -     -     -
     - Isolated Recovered          -     -     -     -     -     -     -  0.75     -  0.25
     - Hospitalized                -     -     -     -     -     -     -     -     -     -
     - Recovered                   -     -     -     -     -     -     -     -     -  1.00

``` r
# Extracting the results
ans <- davis_model |>
  run_multiple_get_results(
    freader = data.table::fread
  )

# Taking a look at the structure
str(ans)
```

    List of 2
     $ outbreak_size   :Classes 'epiworld_multiple_save_i', 'data.table' and 'data.frame':  5050 obs. of  5 variables:
      ..$ sim_num      : int [1:5050] 1 1 1 1 1 1 1 1 1 1 ...
      ..$ date         : int [1:5050] 0 1 2 3 4 5 6 7 8 9 ...
      ..$ virus_id     : int [1:5050] 0 0 0 0 0 0 0 0 0 0 ...
      ..$ virus        : chr [1:5050] "Davis county" "Davis county" "Davis county" "Davis county" ...
      ..$ outbreak_size: int [1:5050] 10 10 10 10 11 12 12 12 12 12 ...
      ..- attr(*, ".internal.selfref")=<externalptr> 
      ..- attr(*, "what")= chr "outbreak_size"
     $ hospitalizations:Classes 'epiworld_multiple_save_i' and 'data.frame':    0 obs. of  6 variables:
      ..$ sim_num : logi(0) 
      ..$ date    : logi(0) 
      ..$ virus_id: logi(0) 
      ..$ tool_id : logi(0) 
      ..$ count   : logi(0) 
      ..$ weight  : logi(0) 
      ..- attr(*, "what")= chr "hospitalizations"
     - attr(*, "class")= chr [1:2] "epiworld_multiple_save" "list"

The function call will get us the results as a list of data.frames
(data.table objects in this case). We will use the `data.table` package
to manipulate the information.

``` r
# Converting into data.table format for convenience
library(data.table)
outbreak_size <- ans$outbreak_size |> as.data.table()
hospitalizations <- ans$hospitalizations |> as.data.table()
```

## Outbreak size

Finally, since we are only interested about the final outbreak size (in
this case), can will collapse the data to get the total number of cases
at the final simulation day. Subsequently, we can plot the results using
the `hist` function:

``` r
# Aggregating to get the final
with(
  outbreak_size,
  {
    plot(
      x = date,
      y = outbreak_size,
      col = adjustcolor("blue", alpha.f = .2),
      pch = 19,
      ylab = "Cases",
      xlab = "Day",
      main = "Measles outbreak size in Short Creek",
      sub = "Mixing model with age and school data (100 simulations)"
    )
})
```

![](README_files/figure-commonmark/timeline-outbreak-size-1.png)

We can also investigate the distribution of the final counts

``` r
# Aggregating to get the final
with(
  outbreak_size[date == max(date)],
  {
    hist(
      outbreak_size,
      main = "Measles outbreak size in Short Creek",
      sub = "Mixing model with age and school data (100 simulations)",
      breaks = 20
    )
})
```

![](README_files/figure-commonmark/hist-outbreak-size-1.png)

## Hospitalizations

In the case of the hospitalizations, we can draw a similar figure. The
hospitalizations data contains the following information:

1.  Cases per virus (just measles in this case).
2.  Cases per tool (or the lack of). Information about “no tool” is
    recorded with a `tool_id == -1`.
3.  The counts (how many records in the data).
4.  Weights.

The weights attribute is to ensure that we take into consideration
counting individuals more than once. For instance, if a model has more
than one tool (not just vaccination), the individual who has two tools
would be included twice in `count`. Thus, if we wanted to count the raw
number of hospitalization cases, we would add across `weight`, but the
`count` variable yields how many individuals were hospitalized under
that combination of tool and virus id.

``` r
hosp_tot <- hospitalizations[, .(total = sum(count)), by = .(sim_num, tool_id)]
hosp_tot[, status := fifelse(tool_id == -1, "Unvax", "Vax")]
hosp_tot[, tool_id := NULL]
```

We can create a couple of boxplot to show how many cases we see per
vaccination status:

``` r
hosp_tot <- merge(
  hosp_tot[status == "Unvax", .(sim_num, unvax = total)],
  hosp_tot[status == "Vax", .(sim_num, vax = total)],
  all = TRUE
)

# Filling zeros
hosp_tot[, unvax := fcoalesce(unvax, 0L)]
hosp_tot[, vax := fcoalesce(vax, 0L)]

hosp_tot[, .(vax, unvax)] |>
  as.matrix() |>
  boxplot(
    ylab = "Count",
    xlab = "Status",
    main = "Hospitalization per vaccination status",
    sub  = "Mixing model with age and school data (100 simulations)"
  )
```

## Final comments
