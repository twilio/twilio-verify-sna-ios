# 0.0.5 (02–02-2024)

### Improvements

- Introduce custom getaddrinfo to ensure DNS resolution exclusively through the cellular network

# 0.0.4 (01–02-2024)

### Fixes

- Append buffer from HTTP request to the responseData.

# 0.0.3 (12–26-2023)

### Fixes

- Continuously read from buffer while no errors occur. The buffer was closing itself after being put on hold, rather than waiting to read the entire package from the SSLRead.

# 0.0.2 (09–26-2022)

### Improvements

- SNA url request changed to POST request (security requirement).

# 0.0.1 (08–22-2022)

### General

- First release.
