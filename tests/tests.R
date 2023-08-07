repos <- "https://cloud.r-project.org"

# avoid timeout error
TIMEOUT <- 180
if(options()$timeout < TIMEOUT) {
  options(timeout = TIMEOUT)
}

# get package list by date
pkg_by_date <- dateback:::.get_pkg_by_date(repos)
head(pkg_by_date)

# get latest package list
pkg_latest <- dateback:::.get_pkg_latest(repos)
head(pkg_latest)

# get archived version list
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
head(df_archive)
