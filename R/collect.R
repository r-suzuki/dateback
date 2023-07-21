collect <- function(
    pkgs,
    date,
    outdir,
    dependencies = c("Depends", "Imports", "LinkingTo"),
    repos = "https://cloud.r-project.org",
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
  pkg_by_date_url <- paste0(repos, "/web/packages/available_packages_by_date.html")
  pkg_latest <- read_html(pkg_by_date_url) %>%
    html_element("table") %>%
    html_table() %>%
    select(Package, Date)

  # installed packages
  pkg_inst <- installed.packages() %>%
    as_tibble() %>%
    select(Package, Version, Priority)

  # packages to be excluded
  pkg_exclude <- if(skip_installed) {
    pkg_installed
  } else {
    if(skip_recommended) {
      pkg_inst %>%
        filter(Priority %in% c("base", "recommended"))
    } else {
      pkg_inst %>%
        filter(Priority == "base")
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

  script <- c(
    paste0("# virtual snapshot on ", date, " for ", paste(pkgs, collapse = ", ")),
    result %>%
      mutate(code = paste0('install.packages("', file.path("src", "contrib", file),
                           '", repos = NULL, type = "source")')) %>%
      pull(code)
  )

  tools::write_PACKAGES("outdir/src/contrib")
  write(script, file.path(outdir, "install.R"))
  capture.output(
    result %>% as.data.frame %>% print,
    file = file.path(outdir, "log_collect.txt")
  )

  return(result)
}
