install <- function(
    pkgs,
    date,
    lib = .libPaths()[1],
    repos = "https://cloud.r-project.org",
    dependencies = c("Depends", "Imports", "LinkingTo"),
    skip_installed = TRUE,
    skip_recommended = FALSE,
    outdir = NULL,
    overwrite = FALSE,
    ...) {

  if(is.null(outdir)) {
    .use_tmp_dir <- TRUE

    outdir <- file.path(tempdir(), "dateback", "downloaded_packages")
    if(file.exists(outdir)) {
      unlink(outdir, recursive = TRUE)
    }
  } else {
    .use_tmp_dir <- FALSE
  }

  try_collect <- try(
    collect(
      pkgs = pkgs,
      date = date,
      outdir = outdir,
      dependencies = dependencies,
      repos = repos,
      skip_installed = skip_installed,
      skip_recommended = skip_recommended,
      overwrite = overwrite
    )
  )
  fail_collect <- inherits(try_collect, "try-error")

  if(!fail_collect) {
    try_install <- try(
      utils::install.packages(
        pkgs = pkgs,
        lib = lib,
        repos = paste0("file:", normalizePath(outdir)),
        dependencies = dependencies,
        type = "source",
        ...
      )
    )
    fail_install <- inherits(try_install, "try-error")
  } else {
    fail_install <- FALSE
  }

  if(fail_collect || fail_install) {
    if(fail_collect) {
      .msg <- "An error occured during dateback::collect()"
    } else if(fail_install) {
      .msg <- "An error occured during utils::install.packages()"
    }

    if(.use_tmp_dir && dir.exists(outdir)) {
      .msg <- paste0(.msg, "\n",
                     "Downloaded contents are in:", "\n",
                     "\t", normalizePath(outdir))
    }

    stop(.msg)

  } else if(.use_tmp_dir) {
    unlink(outdir, recursive = TRUE)
  }

  invisible()
}
