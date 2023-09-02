repos <- "https://cloud.r-project.org"

# avoid timeout error
TIMEOUT <- 60
if(options()$timeout < TIMEOUT) {
  options(timeout = TIMEOUT)
}

try_result <- try({
  cat("get package list by date\n")
  pkg_by_date <- dateback:::.get_pkg_by_date(repos)
  print(head(pkg_by_date))
  cat("\n")

  cat("get latest package list\n")
  pkg_latest <- dateback:::.get_pkg_latest(repos)
  print(head(pkg_latest))
  cat("\n")

  cat("get archived version list\n")
  .get_archived_pkgs <- function(repos) {
    html <- dateback:::.get_html(dateback:::.get_archive_url(repos))
    rows <- grep("<a href=\".*?/\">.*?/",
                 strsplit(
                   paste(html, collapse = " "), # some rows may contain \n
                   "</a>")[[1]],
                 value = TRUE)
    sub(".*<a href=\".*?/\">(.*?)/.*", "\\1", rows)
  }

  archived_pkgs <- .get_archived_pkgs(repos)
  df_archive <- dateback:::.get_df_archive(repos, sample(archived_pkgs, 1))
  print(head(df_archive))
}, silent = TRUE)

if(inherits(try_result, "try-error")) {
  is_timeout <- grepl("readLines", try_result) &&
    any(sapply(names(warnings()), function(x) grepl("Timeout", x)))

  if(any(is_timeout)) {
    cat("Timeout occcured\n")
  } else {
    stop(try_result)
  }
}
