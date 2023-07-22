\name{collect}
\alias{collect}
\alias{install}
\title{Collect and install source packages on a specified date with dependencies}
\usage{
install(pkgs, date, outdir,
        lib = .libPaths()[1],
        repos = "https://cloud.r-project.org",
        dependencies = c("Depends", "Imports", "LinkingTo"),
        skip_installed = TRUE,
        skip_recommended = FALSE,
        overwrite = FALSE,
        ...
  )

collect(pkgs, date, outdir,
        repos = "https://cloud.r-project.org",
        dependencies = c("Depends", "Imports", "LinkingTo"),
        skip_installed = FALSE,
        skip_recommended = TRUE,
        overwrite = FALSE
  )
}
\description{
Collect source packages on a specified date with dependencies.
It automatically downloads \code{tar.gz} files and saves them in \code{outdir}.

\code{outdir} can be used as local repository for \code{install.packages}.
See the example for details.
}
\arguments{
  \item{pkgs}{character vector of the names of packages.}
  \item{date}{character specifying a date in \code{YYYY-MM-DD} format.
    This function tries to find source packages which were available
    on this date.}
  \item{outdir}{character specifying the output directory path.
    It will contain downloaded source packages, and can be used as
    a local package repository. See the example for details.}
  \item{repos}{CRAN mirror URL such as \code{https://cloud.r-project.org}.}
  \item{lib}{character vector of the library directories used in
    \code{utils::install.packages()}.}
  \item{dependencies}{character vector of the dependency level
    for additional downloads. It can include
    \code{c("Depends", "Imports", "LinkingTo", "Suggests")}.}
  \item{skip_installed}{logical. If \code{TRUE} it does not collect files for
    packages already installed.}
  \item{skip_recommended}{logical. If \code{TRUE} it does not collet files for
    "recommended" packages.}
  \item{overwrite}{logical. If \code{TRUE} it overwrites existing files in
    \code{outdir}.}
  \item{\dots}{Arguments to be passed to \code{utils::install.packages}.}
}
\examples{
\dontrun{
# Install 'ranger' package and it's dependecies on the date `2023-03-01`
dateback::install(pkgs = "ranger", date = "2023-03-01")

# Collect packages and install them later (maybe in another system)
dateback::collect(pkgs = "ranger", date = "2023-03-01", outdir = "out_dir")
install.packages(pkgs = "ranger", repos = "file:out_dir")
}
}
