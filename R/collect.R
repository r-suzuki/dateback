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
  # check arguments
  if(missing(pkgs) || is.null(pkgs) || any(is.na(pkgs)) || any(nchar(pkgs) == 0)) {
    stop("'pkgs' should be valid package name(s)")
  }

  if(length(repos) != 1) {
    stop("'repos' should be of length one")
  }

  # check outdir and create outdir/src/contrib
  if(file.exists(outdir)) {
    if(overwrite) {
      unlink(outdir, recursive = TRUE)
    } else {
      msg <- if(!file.info(outdir)$isdir) {
        "outdir should be a directory, not a file."
      } else if(length(list.files(outdir)) > 0){
        "outdir is not empty."
      } else {
        NULL
      }

      if(!is.null(msg)) {
        stop(msg, "\n  ",
             "Set overwrite = TRUE to force overwriting (existing contents will be removed).")
      }
    }
  }

  outdir_src_contrib <- file.path(outdir, "src", "contrib")
  dir.create(outdir_src_contrib, recursive = TRUE)

  # latest packages
  pkg_latest <- .get_pkg_latest(repos)

  # installed packages
  pkg_installed <- as.data.frame(utils::installed.packages())[, c("Package", "Version", "Priority"), drop = FALSE]

  # packages to be excluded
  pkg_exclude <- if(skip_installed) {
    pkg_installed
  } else {
    if(skip_recommended) {
      pkg_installed[pkg_installed$Priority %in% c("base", "recommended"), , drop = FALSE]
    } else {
      pkg_installed[pkg_installed$Priority == "base", , drop = FALSE]
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

  tools::write_PACKAGES(outdir_src_contrib, type = "source")

  # avoid rds version mismatch
  file.remove(file.path(outdir_src_contrib, "PACKAGES.rds"))

  local({
    .width_orig <- options()$width
    on.exit(options(width = .width_orig))

    options(width = 1024)
    utils::capture.output(
      print(result, right = FALSE),
      file = file.path(outdir, "log_collect.txt")
    )
  })

  return(result)
}
