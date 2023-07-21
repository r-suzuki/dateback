.collect <- function(
    pkgs,
    date,
    outdir_src_contrib,
    dependencies,
    repos,
    pkg_latest,
    exclude = NULL) {

  result <- tibble(
    package = character(0),
    file = character(0),
    date = character(0),
    type = character(0),
    url = character(0)
  )

  for(p in pkgs) {
    if(p %in% exclude) {
      # do nothing
    } else {
      use_latest <- use_archive <- FALSE

      if(p %in% pkg_latest$Package) {
        date_latest <- pkg_latest %>%
          filter(Package == p) %>%
          pull(Date)

        if(date_latest <= date) {
          use_latest <- TRUE
        }
      }

      if(!use_latest) {
        get_result <- httr::http_status(httr::GET(paste0(repos, "/src/contrib/Archive/", p, "/")))
        use_archive <- get_result$category == "Success"
      }

      if(use_latest) {
        type <- "latest"
        url <- paste0(repos, "/web/packages/", p, "/")

        tbl <- read_html(url) %>%
          html_elements("table") %>%
          html_table() %>%
          bind_rows()

        tbl_download <- tbl %>%
          filter(grepl("^Package.*source:$", X1)) %>%
          slice(1)

        gzfile_name <- tbl_download %>% pull(X2)
        gzfile_url <- paste0(repos, "/src/contrib/",  gzfile_name)
        gzfile_date <- date_latest
      } else if(use_archive){
        type <- "archive"
        url <- paste0(repos, "/src/contrib/Archive/", p, "/")

        con <- curl::curl(url, open = "r")
        txt <- readLines(con)
        close(con)

        rows <- txt[grepl("<a href=.*\\d{4}-\\d{2}-\\d{2}", txt)]
        tbl <- tibble(
          File = sub('^ *<a href="(.+\\.tar\\.gz)">.*$', '\\1', rows),
          Date = sub('^.*(\\d{4}-\\d{2}-\\d{2}).*$', '\\1', rows)
        )

        tbl_download <- tbl %>%
          filter(Date <= date) %>%
          arrange(desc(Date)) %>%
          slice(1)

        gzfile_name <- tbl_download %>% pull(File)
        gzfile_url <- paste0(url, gzfile_name)
        gzfile_date <- tbl_download %>% pull(Date)
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
      dep_tbl <- desc_get_deps(file.path(uncomp))

      missing <- if(nrow(dep_tbl) > 0) {
        dep_tbl %>%
          filter(package != "R") %>%
          filter(type %in% dependencies) %>%
          filter(!(package %in% exclude)) %>%
          pull(package)
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

      p_tbl <- tibble(package = p, file = gzfile_name,  date = gzfile_date,
                      type = type, url = gzfile_url)

      result <- bind_rows(result, p_tbl)
      exclude <- union(exclude, p)
    }
  }

  return(result)
}
