#' @import utils
NULL

# All of these functions comes from the webshot package:
# Since they are not exported, the code is reproduced below.
# The webshot package is licensed under the GPL-2 license.
# Author : Winston Chang
# Contributors : Yihui Xie, Francois Guillem, Barret Schloerke
# https://github.com/wch/webshot
is_windows <- function() .Platform$OS.type == "windows"

download <- function(url, destfile, mode = "w") {
  if (getRversion() >= "3.3.0") {
    download_no_libcurl(url, destfile, mode = mode)
  } else if (is_windows() && getRversion() < "3.2") {
    # Older versions of R on Windows need setInternet2 to download https.
    download_old_win(url, destfile, mode = mode)
  } else {
    utils::download.file(url, destfile, mode = mode)
  }
}

# Adapted from downloader::download, but avoids using libcurl.
download_no_libcurl <- function(url, ...) {
  # Windows
  if (is_windows()) {
    method <- "wininet"
    utils::download.file(url, method = method, ...)
  } else {
    # If non-Windows, check for libcurl/curl/wget/lynx, then call download.file with
    # appropriate method.

    if (nzchar(Sys.which("wget")[1])) {
      method <- "wget"
    } else if (nzchar(Sys.which("curl")[1])) {
      method <- "curl"

      # curl needs to add a -L option to follow redirects.
      # Save the original options and restore when we exit.
      orig_extra_options <- getOption("download.file.extra")
      on.exit(options(download.file.extra = orig_extra_options))

      options(download.file.extra = paste("-L", orig_extra_options))
    } else if (nzchar(Sys.which("lynx")[1])) {
      method <- "lynx"
    } else {
      stop("no download method found")
    }

    utils::download.file(url, method = method, ...)
  }
}


# Adapted from downloader::download, for R<3.2 on Windows
download_old_win <- function(url, ...) {
  # If we directly use setInternet2, R CMD CHECK gives a Note on Mac/Linux
  seti2 <- `::`(utils, "setInternet2")

  # Check whether we are already using internet2 for internal
  internet2_start <- seti2(NA)

  # If not then temporarily set it
  if (!internet2_start) {
    # Store initial settings, and restore on exit
    on.exit(suppressWarnings(seti2(internet2_start)))

    # Needed for https. Will get warning if setInternet2(FALSE) already run
    # and internet routines are used. But the warnings don't seem to matter.
    suppressWarnings(seti2(TRUE))
  }

  method <- "internal"

  # download.file will complain about file size with something like:
  #       Warning message:
  #         In download.file(url, ...) : downloaded length 19457 != reported length 200
  # because apparently it compares the length with the status code returned (?)
  # so we supress that
  utils::download.file(url, method = method, ...)
}
