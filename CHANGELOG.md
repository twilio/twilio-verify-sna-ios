# 0.0.3 (26–12-2023)

### Fixes

- Continuously read from buffer while no errors occur. The buffer was closing itself after being put on hold, rather than waiting to read the entire package from the SSLRead.

# 0.0.2 (09–26-2022)

### Improvements

- SNA url request changed to POST request (security requirement).

# 0.0.1 (08–22-2022)

### General

- First release.
