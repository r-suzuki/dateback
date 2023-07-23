.get_pkg_latest <- function(repos) {
  pkg_by_date_url <- paste0(repos, "/web/packages/available_packages_by_date.html")
  read_html(pkg_by_date_url) %>%
    html_element("table") %>%
    html_table() %>%
    select(Package, Date) %>%
    return
}

.get_df_binded <- function(url) {
  read_html(url) %>%
    html_elements("table") %>%
    html_table() %>%
    bind_rows() %>%
    return
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
        url <- paste0(repos, "/web/packages/", p, "/")

        df <- .get_df_binded(url)

        df_download <- subset(df, grepl("^Package.*source:$", X1))[1, , drop = FALSE]

        gzfile_name <- df_download$X2
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

        result <- bind_rows(result, result_mis)
        exclude <- union(exclude, result_mis$package)
      }

      p_df <- data.frame(package = p, file = gzfile_name,  date = gzfile_date,
                      status = status, url = gzfile_url,
                      stringsAsFactors = FALSE)

      result <- bind_rows(result, p_df)
      exclude <- union(exclude, p)
    }
  }

  return(result)
}
