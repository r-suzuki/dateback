collect <- function(
    pkgs,
    date,
    outdir,
    repos = "https://cloud.r-project.org",
    dependencies = c("Depends", "Imports", "LinkingTo"),
    skip_installed = FALSE,
    skip_recommended = TRUE,
    overwrite = FALSE
) {

  # check outdir and create outdir/src/contrib
  if(file.exists(outdir)) {
    if(!file.info(outdir)$isdir) {
      stop("outdir should be a directory, not a file")
    } else if(length(list.files(outdir)) > 0 && !overwrite){
      stop("outdir is not empty. Set overwrite = TRUE to force overwriting")
    }
  }
  outdir_src_contrib <- file.path(outdir, "src", "contrib")
  dir.create(outdir_src_contrib, recursive = TRUE)

  # latest packages
  pkg_latest <- .get_pkg_latest(repos)

  # installed packages
  pkg_installed <- as.data.frame(installed.packages())[, c("Package", "Version", "Priority"), drop = FALSE]

  # packages to be excluded
  pkg_exclude <- if(skip_installed) {
    pkg_installed
  } else {
    if(skip_recommended) {
      subset(pkg_installed, Priority %in% c("base", "recommended"))
    } else {
      subset(pkg_installed, Priority == "base")
    }
  }

  # call inner function
  result <- .collect(
    pkgs = pkgs,
    date = date,
    outdir_src_contrib = outdir_src_contrib,
    dependencies = dependencies,
    repos = repos,
    pkg_latest = pkg_latest,
    exclude = pkg_exclude$Package)

  tools::write_PACKAGES(file.path(outdir, "src/contrib"))

  # TODO: as.data.frame can be removed if result is data.frame
  capture.output(
    print(as.data.frame(result)),
    file = file.path(outdir, "log_collect.txt")
  )

  return(result)
}
