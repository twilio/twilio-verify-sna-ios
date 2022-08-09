# Getting the error cause

You can get the cause for an error accessing the associated error

```swift
twilioVerify.processURL(snaUrl) { result in
    switch result {
        case .success:
          return

        case .failure(let error):
            switch error {
                case .cellularNetworkNotAvailable:
                    return

                case .requestError(.instanceNotFound):
                    return

                case .requestError(.invalidUrl):
                    return

                case .requestError(.noResultFromUrl):
                    return

                case .requestError(.networkingError(.requestFinishedWithNoResult)):
                    return

                case .requestError(.networkingError(.cellularRequestError(.cannotConnectSocketToRemoteAddress))):
                    return

                case .requestError(.networkingError(.cellularRequestError(.success))):
                    return

                case .requestError(.networkingError(.cellularRequestError(.unexpectedError))):
                    return

                case .requestError(.networkingError(.cellularRequestError(.unknownHttpResponse))):
                    return

                case .requestError(.networkingError(.cellularRequestError(.errorReadingHttpResponse))):
                    return

                case .requestError(.networkingError(.cellularRequestError(.unableToInstantiateSockets))):
                    return

                case .requestError(.networkingError(.cellularRequestError(.errorPerformingSSLHandshake))):
                    return

                case .requestError(.networkingError(.cellularRequestError(.cannotSpecifySSLIOConnection))):
                    return

                case .requestError(.networkingError(.cellularRequestError(.cannotObtainNetworkInterfaces))):
                    return

                case .requestError(.networkingError(.cellularRequestError(.cannotFindRoutesForHttpRequest))):
                    return

                case .requestError(.networkingError(.cellularRequestError(.cannotSpecifySSLFunctionsNeeded))):
                    return

                case .requestError(.networkingError(.cellularRequestError(.errorPerformingSSLWriteOperation))):
                    return

                case .requestError(.networkingError(.cellularRequestError(.cannotFindRemoteAddressOfRemoteUrl))):
                    return

                case .requestError(.networkingError(.cellularRequestError(.peersCertificateDoesNotMatchWithRequestedUrl))):
                    return

                case .requestError(.networkingError(.cellularRequestError(.sslSessionDidNotCloseGracefullyAfterPerformingSSLReadOperation))):
                    return
            }
    }
}
```

Error description and technical discussion:

```swift
twilioVerify.processURL(snaUrl) { result in
    switch result {
        case .success:
          return

        case .failure(let error):
          let errorDescription = cause.description
          let technicalError = cause.technicalError
    }
}
```
