# Twilio Verify SNA

[![Swift Package Manager Compatible](https://img.shields.io/badge/Swift_Package_Manager-compatible-4BC51D.svg?style=flat")](https://swift.org/package-manager/)
[![Platform](https://img.shields.io/cocoapods/p/TwilioVerify.svg?style=flat)](https://twilio.github.io/twilio-verify-ios/latest/)
[![Swift 5.5](https://img.shields.io/badge/Swift-5.5-orange.svg?style=flat)](https://developer.apple.com/swift/)
[![License](https://img.shields.io/badge/License-Apache%202-blue.svg?logo=law)](https://github.com/twilio/twilio-verify-ios/blob/main/LICENSE)

## Table of Contents

- [About](#About)
- [Dependencies](#Dependencies)
- [Requirements](#Requirements)
- [Documentation](#Documentation)
- [Installation](#Installation)
- [Usage](#Usage)
- [Running the Sample app](#SampleApp)
- [Running the Sample backend](#SampleBackend)
- [Using the sample app](#UsingSampleApp)
- [Errors](#Errors)
- [Validate SNA URL](#ValidateSNAURL)
- [Contributing](#Contributing)
- [License](#License)

<a name='About'></a>

## About

---

Twilio Silent Network Auth will protect you against account takeovers (ATOs) that target your user's phone number by streamlining your methods for verifying mobile number possession. Instead of sending one-time passcodes (OTPs) that can be stolen or forcing users to implement complicated app-based solutions, Twilio Silent Network Auth will verify mobile number possession directly on the device by using its built-in connectivity to the mobile operators’ wireless network.

This SDK will help you with process the SNA URL's provided by our `Verify services` to silently validate a phone number.

<a name='Dependencies'></a>

## Dependencies

---

### External dependencies:

- None

### Internal dependencies:

- **SNANetworking:** used for cellular networking operations, lives as an internal package.

<a name='Requirements'></a>

## Requirements

---

- iOS 12+
- Swift 5.5
- Xcode 14.x

<a name='Documentation'></a>

## Documentation

---

Offical documentation will be added via Twilio docs once this project gets released.

<a name='Installation'></a>

## Installation

---

During the current phase of this project, we only support SPM. We have plans to support CocoaPods and Carthage once we release this product.

### Swift Package Manager

**For pilot stage:** you will need to create a personal access token on your Github account in order to add this dependency via Xcode (assuming that you have 2FA enabled) since this project is private.

`Package.swift`

```swift
dependencies: [
    .package(
        url: "https://github.com/twilio/twilio-verify-sna-ios.git",
        .upToNextMajor(from: "0.0.1")
    )
]
```

<a name='Usage'></a>

## Usage

---

For using the SDK you can follow the next steps:

1. Import the SDK dependency, on your `.swift` file:

```swift
import TwilioVerifySNA
```

2. Instantiate the SDK

```swift
private lazy var twilioVerify: TwilioVerifySNA = TwilioVerifySNASession()
```

3. Process the SNA URL by calling the method:

```swift
func processURL(
  _ url: String,
  onComplete: @escaping ProcessURLCallback
)
```

```swift
twilioVerify.processURL(snaUrlFromBackend) { result in
    switch result {
      case .success:
      // Handle success scenario

      case .failure(let error):
      // Handle error scenario
    }
}
```

_Async alternative:_

```swift
func processURL(_ url: String) async -> ProcessURLResult
```

```swift
let result = await twilioVerify.processURL(snaUrlFromBackend)

switch result {
  case .success:
  // Handle success scenario

  case .failure(let error):
  // Handle error scenario
}
```

4. Full implementation demonstration

```swift
import UIKit
import TwilioVerifySNA

class ViewController: UIViewController {
    private lazy var twilioVerify: TwilioVerifySNA = TwilioVerifySNASession()

     override func viewDidLoad() {
        super.viewDidLoad()
    }

    private func validateSNAURL() async {
        let snaUrlFromBackend = await asyncMethodToGetSNAUrl()

        twilioVerify.processURL(snaUrlFromBackend) { result in
            switch result {
                case .success:
                // Handle success scenario

                case .failure(let error):
                // Handle error scenario
            }
        }
    }
}

```

<a name='SampleApp'></a>

## Running the Sample app

---

For running the demo you will need to create a sample backend, this backend will communicate with the `Twilio Verify Services` and provide to the client a `SNA URL` that this SDK will use to validate across the carrier cellular network.

**Important note:**

The demo app needs to run on a real device with a working SIM-CARD and internet connection (provided by the sim-card, not WiFi).

Currently it's not possible to test the functionality using a simulator.

**To run the sample app:**

1. Clone the repo
2. Open the `TwilioVerifySNA.xcworkspace` file
3. Select the `TwilioVerifySNADemo` project
4. Go to `Signing & Capabilities`
5. Change the Bundle Identifier to something unique, now you have two options:
   A. Create provisioning profiles on your Apple Developer account using the bundle identifier you just assigned
   B. Check the `Automatically manage signing` checkbox with your Apple Developer account logged in.
6. Connect or prepare your test device
7. Run the `TwilioVerifySNADemo` schema on your test device

<a name='SampleBackend'></a>

## Running the Sample backend

---

To be added once the sample backend gets released.

<a name='UsingSampleApp'></a>

## Using the sample app

**To validate a phone number:**

- Set the phone number
  - Available carriers during this phase:
    - US - Verizon, TMO
    - UK - EE, Vodafone, O2 and ThreeUK
    - CA - Bell, Rogers and Telus
- Set the country code (only US during pilot stage)
- Set your sample backend url
- Subit the form by using the CTA button

**Expected behavior:**
The app will ask the network carrier if the provided phone number is the same used on the network request, if the phone number is correct, then the app will redirect to a sucess screen.

<a name='Errors'></a>

## Errors

---

### Celullar network

See `NetworkResult.h`

<table>
  <tr>
    <th>Name</th>
    <th>Description</th>
    <th>Technical cause</th>
  </tr>
  <tr>
    <td>CannotObtainNetworkInterfaces</td>
    <td>Cannot obtain network interfaces of the local system</td>
    <td>Probably you are using a simulator or a device with no sim-card</td>
  </tr>
  <tr>
    <td>CannotFindRemoteAddressOfRemoteUrl</td>
    <td>Cannot find remote address of requested URL	</td>
    <td>The url is corrupted, try generating a new one</td>
  </tr>
    <tr>
    <td>CannotFindRoutesForHttpRequest</td>
    <td>No routes found for HTTP request</td>
    <td>The url is corrupted, try generating a new one</td>
  </tr>
    <tr>
    <td>UnableToInstantiateSockets</td>
    <td>Cannot instantiate socket</td>
    <td>Probably you are using a simulator or a device with no sim-card</td>
  </tr>
    <tr>
    <td>ErrorReadingHttpResponse</td>
    <td>Error occurred while reading HTTP response</td>
    <td>No bytes recieved from the request</td>
  </tr>
    <tr>
    <td>CannotSpecifySSLFunctionsNeeded</td>
    <td>Cannot specify SSL functions needed to perform the network I/O operations</td>
    <td>The url is corrupted, try generating a new one</td>
  </tr>
    <tr>
    <td>CannotSpecifySSLIOConnection</td>
    <td>Error ocurred while specifying SSL I/O connection with peer	</td>
    <td>Probably you are using a simulator or a device with no sim-card</td>
  </tr>
    <tr>
    <td>PeersCertificateDoesNotMatchWithRequestedUrl</td>
    <td>The common name of the peer's certificate doesn't match with URL being requested</td>
    <td>Unknown network error, try again</td>
  </tr>
    <tr>
    <td>ErrorPerformingSSLHandshake</td>
    <td>Error occurred while performing SSL handshake</td>
    <td>The device probably lost internet conenection during the operation</td>
  </tr>
    <tr>
    <td>ErrorPerformingSSLWriteOperation</td>
    <td>Error occurred while performing SSL write operation</td>
    <td>The url is corrupted, try generating a new one</td>
  </tr>
    <tr>
    <td>SSLSessionDidNotCloseGracefullyAfterPerformingSSLReadOperation</td>
    <td>Cannot specify SSL functions needed to perform the network I/O operations</td>
    <td>The url is corrupted, try generating a new one</td>
  </tr>
  <tr>
    <td>UnknownHttpResponse</td>
    <td>Unknown HTTP response	</td>
    <td></td>
  </tr>
</table>

### Networking

See `NetworkRequestProvider+Errors.swift`

<table>
  <tr>
    <th>Name</th>
    <th>Description</th>
    <th>Technical cause</th>
  </tr>
  <tr>
    <td>RequestFinishedWithNoResult</td>
    <td>No response from request</td>
    <td>The request was successful (200 status code) but the networking layer was unable to get the response</td>
  </tr>
  <tr>
    <td>CellularRequestError</td>
    <td>Error processing the URL via cellular network</td>
    <td>The cause will be represented by a Cellular network error</td>
  </tr>
</table>

### Request manager errors

See `RequestManager+Errors.swift`

<table>
  <tr>
    <th>Name</th>
    <th>Description</th>
    <th>Technical cause</th>
  </tr>
  <tr>
    <td>InvalidUrl</td>
    <td>Invalid url, please check the format.</td>
    <td>Unable to convert the url string to an Apple URL struct</td>
  </tr>
  <tr>
    <td>NoResultFromUrl</td>
    <td>Unable to get a valid result from the requested URL.</td>
    <td>Unable to get a redirection path or a result path from the url, probably the SNAURL is corrupted (or maybe expired)</td>
  </tr>
  <tr>
    <td>InstanceNotFound</td>
    <td>Unable to continue url process, instance not found.</td>
    <td>Weak self was nil, make sure that you are instantiating as a dependency this SDK or lazy loading it, do not use this SDK as a computed property.</td>
  </tr>
  <tr>
    <td>NetworkingError</td>
    <td>Check network error cause</td>
    <td></td>
  </tr>
</table>

### Verification errors

See `TwilioVerifySNA+Errors.swift`

<table>
  <tr>
    <th>Name</th>
    <th>Description</th>
    <th>Technical cause</th>
  </tr>
  <tr>
    <td>CellularNetworkNotAvailable</td>
    <td>Cellular network not available</td>
    <td>Cellular network not available, check if the device has cellular internet connection or you are not using a simulator or iPad</td>
  </tr>
  <tr>
    <td>RequestError</td>
    <td>Error processing the SNAURL request, see the RequestError cause for detail</td>
    <td></td>
  </tr>
</table>

### Getting the error cause

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

<a name='Contributing'></a>

## Contributing

---

This project welcomes contributions. Please check out our [Contributing guide](./CONTRIBUTING.md) to learn more on how to get started.

<a name='License'></a>

## License

[Apache © Twilio Inc.](./LICENSE)
