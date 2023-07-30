.get_pkg_by_date <- function(url) {
  tmpfile <- tempfile()
  on.exit(unlink(tmpfile))

  utils::download.file(url, tmpfile, quiet = TRUE)
  html <- readLines(tmpfile)
  rows <- grep("^\\s*<tr>.*$", html, value = TRUE)

  date_col <- sub("^\\s*<tr>\\s*<td>\\s*([^< ]+)\\s*</td>.*$", "\\1", rows)
  pkgs_col <- sub("^.*<span class=\"CRAN\">([^<]+)</span>.*$", "\\1", rows)

  return(data.frame(Package=pkgs_col[-1], Date=date_col[-1]))
}

.get_pkg_latest <- function(repos) {
  # available packages
  pkg_available <- as.data.frame(
    utils::available.packages(repos = repos, type = "source"))

  url <- paste0(repos, "/web/packages/available_packages_by_date.html")
  pkg_by_date <- .get_pkg_by_date(url)

  merge(
    pkg_by_date,
    pkg_available[, c("Package", "Version"), drop = FALSE],
    by = "Package")[, c("Package", "Version", "Date"), drop = FALSE]
}

.get_deps <- function(path, deps) {
  d <- read.dcf(file.path(path, "DESCRIPTION"), fields = deps)

  if(all(is.na(d))) {
    return(character(0))
  } else {
    d_flat <- local({
      tmp <- unlist(strsplit(d[!is.na(d) & d != ""], ","), recursive = TRUE)
      tmp <- trimws(tmp)
      sub("^(\\S+).*$", "\\1", tmp)
    })

    return(d_flat)
  }
}

.find_tar_gz <- function(p, date, repos, pkg_latest) {

  use_latest <- FALSE
  if(p %in% pkg_latest$Package) {
    date_latest <- pkg_latest[pkg_latest$Package == p, "Date"]

    if(date_latest <= date) {
      use_latest <- TRUE
    }
  }

  tar_gz <- list()
  if(use_latest) {
    v <- pkg_latest[pkg_latest$Package == p, "Version"]

    tar_gz$name <- paste0(p, "_", v, ".tar.gz")
    tar_gz$url <- paste0(repos, "/src/contrib/",  tar_gz$name)
    tar_gz$date <- date_latest
    tar_gz$status <- "latest"

    return(tar_gz)

  } else {
    url <- paste0(repos, "/src/contrib/Archive/", p, "/")

    try_result <- try({
      tmpfile <- tempfile()
      on.exit(unlink(tmpfile))

      utils::download.file(url, tmpfile, quiet = TRUE)
      txt <- readLines(tmpfile)
    })

    if(inherits(try_result, "try-error")) {
      stop("Package '", p, "' is not available at ", repos)
    }

    rows <- txt[grepl("<a href=.*\\d{4}-\\d{2}-\\d{2}", txt)]
    df <- data.frame(
      File = sub('^ *<a href="(.+\\.tar\\.gz)">.*$', '\\1', rows),
      Date = sub('^.*(\\d{4}-\\d{2}-\\d{2}).*$', '\\1', rows),
      stringsAsFactors = FALSE
    )

    df_download <- local({
      tmp <- df[df$Date <= date, , drop = FALSE]
      tmp <- tmp[order(tmp$Date, decreasing = TRUE)[1], , drop = FALSE]
      tmp
    })

    tar_gz$name <- df_download$File
    tar_gz$url <- paste0(url, tar_gz$name)
    tar_gz$date <- df_download$Date
    tar_gz$status <- "archive"

    return(tar_gz)
  }

}

.collect <- function(
    pkg_vers,
    date,
    outdir_src_contrib,
    dependencies,
    repos,
    pkg_latest,
    exclude = NULL) {

  result <- data.frame(
    package = character(0),
    file = character(0),
    date = character(0),
    status = character(0),
    url = character(0),
    stringsAsFactors = FALSE
  )

  for(p in names(pkg_vers)) {
    if(p %in% exclude) {
      # do nothing
    } else {
      # find version
      tar_gz <- .find_tar_gz(p, date = date, repos = repos,
                             pkg_latest = pkg_latest)

      # Download and unpack tar.gz
      gzf <- file.path(outdir_src_contrib, basename(tar_gz$url))
      utils::download.file(url = tar_gz$url, destfile = gzf)

      tmpd <- tempdir()
      utils::untar(gzf, exdir = tmpd)
      uncomp <- file.path(tmpd, p)

      dep <- .get_deps(path = uncomp, deps = dependencies)

      missing <- setdiff(dep, c("R", exclude))
      if(length(missing) > 0) {
        # set versions
        missing_vers <- lapply(missing, function(m) {
          if(m %in% names(pkg_vers)) {
            return(pkg_vers[[m]])
          } else {
            return(NA_character_)
          }
        })
        names(missing_vers) <- missing

        cl <- match.call()
        cl$pkg_vers <- missing_vers
        cl$exclude <- c(exclude, result$package)

        result_mis <- eval(cl)

        result <- rbind(result, result_mis)
        exclude <- union(exclude, result_mis$package)
      }

      p_df <- data.frame(package = p, file = tar_gz$name,  date = tar_gz$date,
                      status = tar_gz$status, url = tar_gz$url,
                      stringsAsFactors = FALSE)

      result <- rbind(result, p_df)
      exclude <- union(exclude, p)
    }
  }

  return(result)
}
