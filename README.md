
<!-- README.md is generated from README.Rmd. Please edit that file -->
NetCoupler
==========

[![lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental) [![Travis build status](https://travis-ci.org/ClemensWittenbecher/NetCoupler.svg?branch=master)](https://travis-ci.org/ClemensWittenbecher/NetCoupler) [![Coverage status](https://codecov.io/gh/ClemensWittenbecher/NetCoupler/branch/master/graph/badge.svg)](https://codecov.io/github/ClemensWittenbecher/NetCoupler?branch=master)

The goal of NetCoupler is to estimate causal links between metabolomics and disease incidence. The *NetCoupler-algorithm* links conditional dependency networks with time-to-event data and identifies direct effects of correlated, high-dimensional exposures on time-to-event data.

The NetCoupler's input is multi-layer information from prospective studies, including interdependent variables that constitute the central network of interest (e.g., metabolomics data), time-to-disease incidence, and optionally information on factors that influence the network (such as lifestyle variables, or genetic determinants).

The output is a list of network variables that directly (independent of other network variables) influence time-to-disease incidence. Optionally, NetCoupler also identifies the sensitivity of network variables to exogenous challenges (such as genetic variation or lifestyle).

Results can be graphically displayed as joint network model. For example, to a data-driven metabolomics network links can be added that reflect network-independent associations of metabolites with disease risk and lifestyle habits (or genetics) with these disease-related metabolites.

Installation
============

So far there is only the development version.

``` r
# install.packages("remotes")
remotes::install_github("ClemensWittenbecher/NetCoupler")
```
