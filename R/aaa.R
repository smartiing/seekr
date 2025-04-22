# https://testthat.r-lib.org/reference/local_mocked_bindings.html
#
# Base functions
#
# To mock a function in the base package, you need to make sure
# that you have a binding for this function in your package. It's easiest to do
# this by binding the value to NULL. For example, if you wanted to mock interactive()
# in your package, you'd need to include this code somewhere in your package :
#
readBin = NULL
