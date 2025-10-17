# Install flextable and officer packages for Word table formatting

# Create user-level library if it doesn't exist
user_lib <- file.path(Sys.getenv("LOCALAPPDATA"), "R", "win-library",
                      paste0(R.version$major, ".", strsplit(R.version$minor, ".", fixed = TRUE)[[1]][1]))
if (!dir.exists(user_lib)) {
  dir.create(user_lib, recursive = TRUE)
}

# Set library path
.libPaths(c(user_lib, .libPaths()))

# Install packages
packages <- c("systemfonts", "gdtools", "flextable", "officer")
install.packages(packages, repos = "https://cloud.r-project.org", lib = user_lib)

cat("\nInstallation complete! Packages installed to:", user_lib, "\n")
cat("Installed packages:\n")
print(packages)
