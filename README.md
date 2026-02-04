# Tabletop ABM for Davis County, Utah

This repository presents a tabletop agent-based model (ABM) for disease
spread in Davis County, Utah. The model utilizes age mixing data to
simulate disease transmission dynamics under various intervention
scenarios, including isolation, quarantine, and post-exposure
prophylaxis (PEP).

This is not a real situation and is intended for educational purposes
only.

## Description of the model

The implemented model is a Susceptible Exposed Infectious Hospitalized
Recovered (SEIRH) model with mixing and quarantine features. The model
features what we call entities, which are subgroups of the population
defined by age groups and schools. School-age agents are assigned to
schools based on the population data, and the rest of the population is
assigned to age groups. The mixing patterns are given by an age-based
contact matrix based on the Polymod study.

The model features contact tracing, isolation of detected cases, and
quarantine of contacts. Detection happens with uncertainty (80% success
rate), and agents isolate and move to the quarantine states with
certainty (for now). The model also allows for the implementation of
post-exposure prophylaxis (PEP) for contacts of detected cases. The PEP
is implemented as a baseline tool that reduces the probability of
becoming infected and transmitting the disease.

To execute this model, it is recommended to run it in a high-performance
computing environment due to its computational intensity, especially
when simulating multiple scenarios. The model is fast, but the Davis
county population is large (over 350,000), and running multiple
simulations can be time-consuming on a standard personal computer.

The following diagram illustrates the compartments and transitions in
the SEIRH model:

``` mermaid
flowchart TB

    %% Disease progression states
    subgraph Main[Disease Progression]
        direction TB
        S[Susceptible]
        E[Exposed]
        In[Infected]
        H[Hospitalized]
        R[Recovered]
    end

    S --> E
    E --> In
    In --> H
    H --> R
    In --> R

    %% Quarantine states
    Dh[Detected<br>Hospitalized]
    Qs[Quarantined<br>Susceptible]
    Qe[Quarantined<br>Exposed]
    I[Isolated]
    Ir[Isolated<br>Recovered]

    %% Infected to
    In <==> I
    In --> Ir
    In --> Dh

    %% Isolated to
    I --> R
    I --> Ir
    I --> H
    I --> Dh

    %% Susceptible quarantined
    S <==> Qs

    %% Exposed
    E <==> Qe

    Qe --> I
    Qe --> In

    Dh --> R

    %% Isolated recovered
    Ir --> R
```

## Links to the scenarios

The following table links to the reports generated for each of the
scenarios run for Davis County:

| R0  | Isolation | Quarantine | PEP | Link                                                                    |
|:----|:----------|:-----------|:----|:------------------------------------------------------------------------|
| 1.1 | no        | no         | no  | [View Report](scenarios/R0_1.1_isolation_no_quarantine_no.md)           |
| 1.1 | no        | no         | yes | [View Report](scenarios/R0_1.1_isolation_no_quarantine_no_pep_yes.md)   |
| 1.1 | yes       | no         | no  | [View Report](scenarios/R0_1.1_isolation_yes_quarantine_no.md)          |
| 1.1 | yes       | no         | yes | [View Report](scenarios/R0_1.1_isolation_yes_quarantine_no_pep_yes.md)  |
| 1.1 | yes       | yes        | no  | [View Report](scenarios/R0_1.1_isolation_yes_quarantine_yes.md)         |
| 1.1 | yes       | yes        | yes | [View Report](scenarios/R0_1.1_isolation_yes_quarantine_yes_pep_yes.md) |
| 1.5 | no        | no         | no  | [View Report](scenarios/R0_1.5_isolation_no_quarantine_no.md)           |
| 1.5 | no        | no         | yes | [View Report](scenarios/R0_1.5_isolation_no_quarantine_no_pep_yes.md)   |
| 1.5 | yes       | no         | no  | [View Report](scenarios/R0_1.5_isolation_yes_quarantine_no.md)          |
| 1.5 | yes       | no         | yes | [View Report](scenarios/R0_1.5_isolation_yes_quarantine_no_pep_yes.md)  |
| 1.5 | yes       | yes        | no  | [View Report](scenarios/R0_1.5_isolation_yes_quarantine_yes.md)         |
| 1.5 | yes       | yes        | yes | [View Report](scenarios/R0_1.5_isolation_yes_quarantine_yes_pep_yes.md) |
| 1.9 | no        | no         | no  | [View Report](scenarios/R0_1.9_isolation_no_quarantine_no.md)           |
| 1.9 | no        | no         | yes | [View Report](scenarios/R0_1.9_isolation_no_quarantine_no_pep_yes.md)   |
| 1.9 | yes       | no         | no  | [View Report](scenarios/R0_1.9_isolation_yes_quarantine_no.md)          |
| 1.9 | yes       | no         | yes | [View Report](scenarios/R0_1.9_isolation_yes_quarantine_no_pep_yes.md)  |
| 1.9 | yes       | yes        | no  | [View Report](scenarios/R0_1.9_isolation_yes_quarantine_yes.md)         |
| 1.9 | yes       | yes        | yes | [View Report](scenarios/R0_1.9_isolation_yes_quarantine_yes_pep_yes.md) |

Links to the scenario reports for Davis County

## Software

The simulations used the R package `epiworldR` version
`r`packageVersion(“epiworldR”)\`\`, which can be found at
<https://github.com/UofUEpiBio/epiworldR>, and R version R version 4.4.0
(2024-04-24).
