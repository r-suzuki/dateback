\name{install}
\alias{collect}
\alias{install}
\title{Collect and install source packages on a specified date with dependencies}
\usage{
install(pkgs, date,
        lib = .libPaths()[1],
        repos = "https://cloud.r-project.org",
        dependencies = c("Depends", "Imports", "LinkingTo"),
        skip_installed = TRUE,
        skip_recommended = FALSE,
        outdir = NULL,
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
Collect and install source packages on a specified date with dependencies.

\code{install()} automatically downloads and installs \code{tar.gz} files
with dependencies, all of which were available on a specific day.

Downloaded contents are saved in \code{outdir} (if set) which can be
used as a local repository for \code{\link[utils]{install.packages}()}.

Use \code{collect()} to create a local repository without installation.
See the example for details.
}
\arguments{
  \item{pkgs}{character vector of the names of packages.}
  \item{date}{character specifying a date in \code{YYYY-MM-DD} format.
    It tries to find the latest version of source packages on this date.}
  \item{outdir}{character specifying the output directory path.
    In \code{install()} it can be \code{NULL} to use a temporary directory.
    It will contain downloaded source packages, and can be used as
    a local package repository. See the example for details.}
  \item{repos}{CRAN mirror URL such as \code{https://cloud.r-project.org}.}
  \item{lib}{character vector of the library directories used in
    \code{\link[utils]{install.packages}()}.}
  \item{dependencies}{character vector of the dependency level
    for additional downloads. It can include
    \code{c("Depends", "Imports", "LinkingTo", "Suggests")}.}
  \item{skip_installed}{logical. If \code{TRUE} it does not collect files for
    packages already installed.}
  \item{skip_recommended}{logical. If \code{TRUE} it does not collet files for
    "recommended" packages.}
  \item{overwrite}{logical. If \code{TRUE} it overwrites existing files in
    \code{outdir}.}
  \item{\dots}{Arguments to be passed to \code{\link[utils]{install.packages}()}}.
}
\value{\code{data.frame} containing information about collected packages.
Please notice that it is intended for logging, and the structure of
this object may change in future releases.}
\note{This package was originally developed to (partially) substitute the
"CRAN Time Machine" (or "MRAN Time Machine"), which retired in July 2023
(\url{https://blog.revolutionanalytics.com/2023/01/mran-time-machine-retired.html}).

Posit Package Manager (\url{https://packagemanager.posit.co/}) has a snapshot
feature, so can be used as a direct replacement for CRAN Time Machine.
Windows/Mac users would greatly benefit from it since binary packages are also
available.
}
\examples{
\dontrun{

# Install 'ranger' package and its dependecies on the date 2023-03-01
dateback::install(pkgs = "ranger", date = "2023-03-01")

# Collect packages and install them later (maybe on another system)
dateback::collect(pkgs = "ranger", date = "2023-03-01", outdir = "local_repo")
install.packages(pkgs = "ranger", repos = "file:local_repo")
}
}
