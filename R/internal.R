.get_html <- function(url_str) {
  con <- base::url(url_str)
  on.exit(close(con))

  readLines(con)
}

.get_pkg_by_date <- function(repos) {
  url_str <- paste0(repos, "/web/packages/available_packages_by_date.html")
  html <- .get_html(url_str)

  # get table rows from html.
  rows <- grep("(<th|<td)",
               strsplit(
                 paste(html, collapse = " "), # some rows may contain \n
                 "<tr>|</tr>")[[1]],
               value = TRUE)

  # get first column as date
  date_col <- sub("^.*<td>\\s*(\\S*?)\\s*</td>.*$", "\\1", rows[-1])

  # get package name in <span class = "CRAN">
  pkgs_col <- sub("^.*<span class=\"CRAN\">(.*?)</span>.*$", "\\1", rows[-1])

  return(data.frame(Package = pkgs_col, Date = date_col))
}

.get_pkg_latest <- function(repos) {
  # available packages
  pkg_available <- as.data.frame(
    utils::available.packages(repos = repos, type = "source"))

  pkg_by_date <- .get_pkg_by_date(repos)

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
      sub("^([^ (]+).*$", "\\1", tmp) # "pkg (>= x.y.z)" is expected, but "pkg(>= x.y.z)" exists
    })

    return(d_flat)
  }
}

.get_archive_url <- function(repos) {
  paste0(repos, "/src/contrib/Archive/")
}

.get_archive_url_package <- function(repos, package) {
  paste0(.get_archive_url(repos), package, "/")
}

.get_df_archive <- function(repos, package) {
  url_str <- .get_archive_url_package(repos, package)
  try_result <- try(txt <- .get_html(url_str))

  if(inherits(try_result, "try-error")) {
    stop("Package '", package, "' is not available at ", repos)
  }

  rows <- txt[grepl("<a href=.*\\d{4}-\\d{2}-\\d{2}", txt)]
  df <- data.frame(
    File = sub('^ *<a href="(.+\\.tar\\.gz)">.*$', '\\1', rows),
    Date = sub('^.*(\\d{4}-\\d{2}-\\d{2}).*$', '\\1', rows),
    stringsAsFactors = FALSE
  )

  return(df)
}

.collect <- function(
    pkgs,
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

  for(p in pkgs) {
    if(p %in% exclude) {
      # do nothing
    } else {
      use_latest <- FALSE

      if(p %in% pkg_latest$Package) {
        date_latest <- pkg_latest[pkg_latest$Package == p, "Date"]

        if(date_latest <= date) {
          use_latest <- TRUE
        }
      }

      if(use_latest) {
        status <- "latest"
        v <- pkg_latest[pkg_latest$Package == p, "Version"]
        gzfile_name <- paste0(p, "_", v, ".tar.gz")
        gzfile_url <- paste0(repos, "/src/contrib/",  gzfile_name)
        gzfile_date <- date_latest
      } else {
        status <- "archive"

        # get data.frame of archived versions
        df <- .get_df_archive(repos, p)

        df_download <- local({
          tmp <- df[df$Date <= date, , drop = FALSE]
          tmp <- tmp[order(tmp$Date, decreasing = TRUE)[1], , drop = FALSE]
          tmp
        })

        gzfile_name <- df_download$File
        gzfile_url <- paste0(.get_archive_url_package(repos, p), gzfile_name)
        gzfile_date <- df_download$Date
      }

      # Download and uncompress tar.gz
      gzf <- file.path(outdir_src_contrib, basename(gzfile_url))
      utils::download.file(url = gzfile_url, destfile = gzf)

      tmpd <- tempdir()
      utils::untar(gzf, exdir = tmpd)
      uncomp <- file.path(tmpd, p)

      dep <- .get_deps(path = uncomp, deps = dependencies)

      missing <- setdiff(dep, c("R", exclude))

      if(length(missing) > 0) {
        cl <- match.call()
        cl$pkgs <- missing
        cl$exclude <- c(exclude, result$package)

        result_mis <- eval(cl)

        result <- rbind(result, result_mis)
        exclude <- union(exclude, result_mis$package)
      }

      p_df <- data.frame(package = p, file = gzfile_name,  date = gzfile_date,
                      status = status, url = gzfile_url,
                      stringsAsFactors = FALSE)

      result <- rbind(result, p_df)
      exclude <- union(exclude, p)
    }
  }

  return(result)
}
