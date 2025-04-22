# check_flag_or_scalar_integerish -----------------------------------------

test_that("check_flag_or_scalar_integerish() returns TRUE for valid inputs", {
  expect_identical(check_flag_or_scalar_integerish(TRUE), TRUE)
  expect_identical(check_flag_or_scalar_integerish(FALSE), TRUE)
  expect_identical(check_flag_or_scalar_integerish(1L), TRUE)
  expect_identical(check_flag_or_scalar_integerish(0), TRUE)
  expect_identical(check_flag_or_scalar_integerish(3.0), TRUE) # still integerish
})

test_that("check_flag_or_scalar_integerish() returns error message for invalid inputs", {
  expect_type(check_flag_or_scalar_integerish("yes"), "character")
  expect_type(check_flag_or_scalar_integerish(c(TRUE, FALSE)), "character")
  expect_type(check_flag_or_scalar_integerish(c(1L, 2L)), "character")
  expect_type(check_flag_or_scalar_integerish(NA), "character")
  expect_type(check_flag_or_scalar_integerish(NULL), "character")
  expect_type(check_flag_or_scalar_integerish(list(TRUE)), "character")
})


# assert_flag_or_scalar_integerish ----------------------------------------

test_that("assert_flag_or_scalar_integerish() passes silently for valid inputs", {
  expect_silent(assert_flag_or_scalar_integerish(TRUE))
  expect_silent(assert_flag_or_scalar_integerish(1))
})

test_that("assert_flag_or_scalar_integerish() throws error for invalid inputs", {
  expect_error(assert_flag_or_scalar_integerish("no"))
  expect_error(assert_flag_or_scalar_integerish(c(TRUE, FALSE)))
  expect_error(assert_flag_or_scalar_integerish(NULL))
  expect_error(assert_flag_or_scalar_integerish(1.5))
  expect_error(assert_flag_or_scalar_integerish(c(1, 2, 3, 4L, 5.05)))
})
