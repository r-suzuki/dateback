# dateback

## Overview

`dateback` works like a virtual CRAN snapshot for source packages.
It automatically downloads `tar.gz` files with dependencies,
all of which were available on a specific day.

The output directory can be used as a local package repository.

## Install

```R
devtools::install_github("r-suzuki/dateback")
```

## Example
To collect `ranger` package and it's dependent packages on the date `2023-03-01`:

```R
dateback::collect(pkgs = "ranger", date = "2023-03-01", outdir = "outdir")
```

It downloads the source `tar.gz` files which were available on the day.
Here is an excerpt from the log file:

```
    package                       file       date    type
1      Rcpp         Rcpp_1.0.10.tar.gz 2023-01-22 archive
2 RcppEigen RcppEigen_0.3.3.9.3.tar.gz 2022-11-05  latest
3    ranger       ranger_0.14.1.tar.gz 2022-06-18 archive
```

The output directory can be used as a local package repository:

```R
install.packages(pkgs = "ranger", repos = "file:outdir")
```

## Details
This package aims to (partially) substitute the "CRAN Time Machine"
(or "MRAN Time Machine") and its related `checkpoint` package,
which no longer work because of the [retirement in July 2023](https://blog.revolutionanalytics.com/2023/01/mran-time-machine-retired.html).

As mentioned in the above URL, `miniCRAN` package would be helpful
if you want to archive the current packages and will use it in the future.

`dateback` will be a better alternative if you:

- haven't archived packages in advance, but need them anyway
- wish to find a date when everything went fine
- just need source package files for Docker images

## NOTE
This project is at the very beginning stage, so everything can be changed shortly.
