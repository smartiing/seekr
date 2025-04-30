# TODO: optimize this function
mean_safe <- function(x) {
  if (length(x) == 0) return(NA)
  mean(x, na.rm = TRUE)
}

sd_safe <- function(x) {
  if (length(x) <= 1) return(NA)
  sd(x, na.rm = TRUE)
}

print_vector <- function(v) {
  print(paste('Vector of length', length(v)))
}
