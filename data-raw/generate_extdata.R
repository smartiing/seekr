# This script generates the files in inst/extdata/ for examples and documentation.
# Run manually when needed.

# --- 1. script1.R ---
writeLines(c(
  "add_one <- function(x) {",
  "  return(x + 1)",
  "}",

  "",
  "capitalize <- function(txt) {",
  "  toupper(substr(txt, 1, 1))",
  "}",

  "",
  "say_hello <- function(name) {",
  "  paste('Hello', name)",
  "}"
), "inst/extdata/script1.R")


# --- 2. script2.R ---
writeLines(c(
  "# TODO: optimize this function",
  "mean_safe <- function(x) {",
  "  if (length(x) == 0) return(NA)",
  "  mean(x, na.rm = TRUE)",
  "}",

  "",
  "sd_safe <- function(x) {",
  "  if (length(x) <= 1) return(NA)",
  "  sd(x, na.rm = TRUE)",
  "}",

  "",
  "print_vector <- function(v) {",
  "  print(paste('Vector of length', length(v)))",
  "}"
), "inst/extdata/script2.R")


# --- 3. iris.csv ---
write.csv(iris, "inst/extdata/iris.csv", row.names = FALSE)

# --- 4. mtcars.csv ---
write.csv(mtcars, "inst/extdata/mtcars.csv", row.names = TRUE)


# --- 5. server.log ---
set.seed(42)
levels <- c("INFO", "ERROR", "DEBUG", "WARNING")
messages <- c(
  "Starting process", "Connection successful", "Failed to authenticate",
  "Retrying request", "Disk usage high", "Timeout reached", "Loading config",
  "User login failed", "Restart scheduled"
)
log_lines <- replicate(40, {
  lvl <- sample(levels, 1)
  msg <- sample(messages, 1)
  ts <- format(Sys.time() - runif(1, 0, 100000), "%Y-%m-%d %H:%M:%S")
  paste(ts, lvl, ":", msg)
})
writeLines(log_lines, "inst/extdata/server.log")


# --- 6. config.yaml ---
writeLines(c(
  "database:",
  "  host: localhost",
  "  port: 5432",
  "  user: admin",
  "  password: secret",
  "",
  "logging:",
  "  level: INFO",
  "  filepath: /var/log/myapp.log",
  "",
  "features:",
  "  enable_tracking: true",
  "  max_users: 100"
), "inst/extdata/config.yaml")


# --- 7. data.json ---
writeLines(c(
  "{",
  '  "users": [',
  '    { "id": 1, "name": "Alice", "active": true },',
  '    { "id": 2, "name": "Bob", "active": false }',
  '  ],',
  '  "version": "1.0.3",',
  '  "metadata": {',
  '    "timestamp": "2024-04-30T12:00:00Z",',
  '    "source": "internal" ',
  '  }',
  "}"
), "inst/extdata/data.json")
