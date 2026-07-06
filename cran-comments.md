## R CMD check results

0 errors | 0 warnings | 1 note

Possibly misspelled words in DESCRIPTION:
- composable
- inspectable

These are intentional terms used to describe the package workflow.

## Test environments

- Local: 0 errors | 0 warnings | 0 notes
- GitHub Actions: 0 errors | 0 warnings | 0 notes
- win-builder R-devel: 0 errors | 0 warnings | 1 note (spelling)

I attempted to run the package on the public MacBuilder service using
`devtools::check_mac_release()`, but the service has been unavailable at least 
since the 6th of July.
