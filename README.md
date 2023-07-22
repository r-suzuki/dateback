# dateback

## Overview

`dateback` is an R package that works like a virtual CRAN snapshot for source packages.
It automatically downloads and installs `tar.gz` files with dependencies,
all of which were available on a specific day.

## Install

```R
devtools::install_github("r-suzuki/dateback")
```

It will also be submitted to CRAN (after the "submission offline" period from Jul 21 to Aug 7, 2023).

## Example
To install `ranger` package and it's dependencies on the date `2023-03-01`:

```R
dateback::install(pkgs = "ranger", date = "2023-03-01")
```

Or you can collect packages first, and install them later on (maybe in another system).

```R
dateback::collect(pkgs = "ranger", date = "2023-03-01", outdir = "out_dir")
```

It downloads the source `tar.gz` files which were available on the day.
Here is an excerpt from the log:

```
    package                       file       date  status
1      Rcpp         Rcpp_1.0.10.tar.gz 2023-01-22 archive
2 RcppEigen RcppEigen_0.3.3.9.3.tar.gz 2022-11-05  latest
3    ranger       ranger_0.14.1.tar.gz 2022-06-18 archive
```

The output directory can be used as a local package repository:

```R
install.packages(pkgs = "ranger", repos = "file:out_dir")
```

## Details
This package aims to (partially) substitute the "CRAN Time Machine"
(or "MRAN Time Machine") and its related `checkpoint` package,
which no longer work because of the [retirement in July 2023](https://blog.revolutionanalytics.com/2023/01/mran-time-machine-retired.html).

As mentioned in the above URL, `miniCRAN` package would be a better choice
if you want to archive the current packages and will use them in the future.

`dateback` will be helpful if you:

- haven't archived packages in advance, but need them anyway
- wish to find a date when everything went fine
- just need source package files for Docker images

## NOTE
This project is at the very beginning stage, so everything can be changed shortly.
