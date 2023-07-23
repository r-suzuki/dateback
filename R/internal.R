.get_pkg_by_date <- function(url) {
  tmpfile <- tempfile()
  on.exit(unlink(tmpfile))

  download.file(url, tmpfile, quiet = TRUE)
  html <- readLines(tmpfile)
  rows <- grep("^\\s*<tr>.*</tr>\\s*$", html, value = TRUE)

  date_col <- sub("^\\s*<tr>\\s*<td>\\s*([^< ]+)\\s*</td>.*$", "\\1", rows)
  pkgs_col <- sub("^.*<span class=\"CRAN\">([^<]+)</span>.*$", "\\1", rows)

  return(data.frame(Package=pkgs_col[-1], Date=date_col[-1]))
}

.get_pkg_latest <- function(repos) {
  # available packages
  pkg_available <- as.data.frame(utils::available.packages(repos = repos, type = "source"))

  url <- paste0(repos, "/web/packages/available_packages_by_date.html")
  pkg_by_date <- .get_pkg_by_date(url)

  merge(
    pkg_by_date,
    pkg_available[, c("Package", "Version"), drop = FALSE],
    by = "Package")[, c("Package", "Version", "Date"), drop = FALSE]
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
      use_latest <- use_archive <- FALSE

      if(p %in% pkg_latest$Package) {
        date_latest <- subset(pkg_latest, Package == p)$Date

        if(date_latest <= date) {
          use_latest <- TRUE
        }
      }

      if(!use_latest) {
        get_result <- httr::http_status(httr::GET(paste0(repos, "/src/contrib/Archive/", p, "/")))
        use_archive <- get_result$category == "Success"
      }

      if(use_latest) {
        status <- "latest"
        v <- subset(pkg_available, Package == p)$Version
        gzfile_name <- paste0(p, "_", v, ".tar.gz")
        gzfile_url <- paste0(repos, "/src/contrib/",  gzfile_name)
        gzfile_date <- date_latest
      } else if(use_archive){
        status <- "archive"
        url <- paste0(repos, "/src/contrib/Archive/", p, "/")

        con <- curl::curl(url, open = "r")
        txt <- readLines(con)
        close(con)

        rows <- txt[grepl("<a href=.*\\d{4}-\\d{2}-\\d{2}", txt)]
        df <- data.frame(
          File = sub('^ *<a href="(.+\\.tar\\.gz)">.*$', '\\1', rows),
          Date = sub('^.*(\\d{4}-\\d{2}-\\d{2}).*$', '\\1', rows),
          stringsAsFactors = FALSE
        )

        df_download <- local({
          tmp <- subset(df, Date <= date)
          tmp <- tmp[order(tmp$Date, decreasing = TRUE)[1], , drop = FALSE]
          tmp
        })

        gzfile_name <- df_download$File
        gzfile_url <- paste0(url, gzfile_name)
        gzfile_date <- df_download$Date
      } else {
        stop("Package '", p, "' is not available at ", repos)
      }

      # Download and uncompress tar.gz
      gzf <- file.path(outdir_src_contrib, basename(gzfile_url))
      download.file(url = gzfile_url, destfile = gzf)

      tmpd <- tempdir()
      untar(gzf, exdir = tmpd)

      uncomp <- file.path(tmpd, p)

      # table of dependencies
      dep_df <- desc_get_deps(file.path(uncomp))

      missing <- if(nrow(dep_df) > 0) {
        subset(dep_df, package != "R" &
                 type %in% dependencies &
                 !(package %in% exclude)
               )$package
      } else {
        character(0)
      }

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
