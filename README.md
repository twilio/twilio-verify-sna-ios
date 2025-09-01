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
- [Logger](#Logger)
- [Errors](#Errors)
- [Validate SNA URL](#ValidateSNAURL)
- [Contributing](#Contributing)
- [License](#License)

<a name='About'></a>

## About

---

Twilio Silent Network Auth will protect you against account takeovers (ATOs) that target your user's phone number by streamlining your methods for verifying mobile number possession. Instead of sending one-time passcodes (OTPs) that can be stolen or forcing users to implement complicated app-based solutions, Twilio Silent Network Auth will verify mobile number possession directly on the device by using its built-in connectivity to the mobile operators’ wireless network.

This SDK will help you with processing the SNA URL's provided by our `Verify services` to silently validate a phone number.

See <a href="https://www.twilio.com/docs/verify/sna/tech-overview">Technical Overview</a>

See <a href="https://www.twilio.com/docs/verify/sna">Silent Network Auth Overview</a>

<a name='Dependencies'></a>

## Dependencies

---

### External dependencies:

- None

### Internal dependencies:

- None

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
        .upToNextMajor(from: "1.0.0")
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
private lazy var twilioVerify: TwilioVerifySNA = TwilioVerifySNABuilder.build()
```

3. Test cellular connectivity before attempting an SNA authentication (optional):

```swift
func testConnectivity(
  to host: String,
  port: UInt16,
  completion: @escaping (Bool) -> Void
)
```

```swift
twilioVerify.testConnectivity(to: "apple.com", port: 80) { isConnected in
    if isConnected {
        // Proceed with SNA URL processing
    } else {
        // Handle the case where cellular connectivity is unavailable
    }
}
```

_Async alternative also available (iOS 13+)._

4. Process the SNA URL by calling the method:

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

5. Full implementation demonstration

```swift
import UIKit
import TwilioVerifySNA

class ViewController: UIViewController {
  private lazy var twilioVerify: TwilioVerifySNA = TwilioVerifySNABuilder.build()

     override func viewDidLoad() {
        super.viewDidLoad()
    }

    private func validateSNAURL() {
        // First check for cellular connectivity
        twilioVerify.testConnectivity(to: "apple.com", port: 80) { [weak self] isConnected in
            guard isConnected else {
                // Handle the case where cellular connectivity is unavailable
                return
            }
            
            // Get SNA URL from backend
            self?.getBackendSNAUrl { snaUrlFromBackend in
                // Process the SNA URL
                self?.twilioVerify.processURL(snaUrlFromBackend) { result in
                    switch result {
                        case .success:
                        // Handle success scenario

                        case .failure(let error):
                        // Handle error scenario
                    }
                }
            }
        }
    }
    
    private func getBackendSNAUrl(completion: @escaping (String) -> Void) {
        // Implementation to get SNA URL from your backend
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

* Configure a [Verify Service](https://console.twilio.com/us1/develop/verify/services).
* Go to: [Verify SNA Sample Backend](https://www.twilio.com/code-exchange/verify-sna) 
* Use the `Quick Deploy to Twilio` option
  * You should log in to your Twilio account.
  * Enter the `Account Sid`, `Auth Token`, `Verify Service Sid`, `Sync Service Sid` and `Sync Map Sid` you created above.
    * Create `Sync Map Sid` by clicking on the Service > Maps tab and click the `Create new Sync Map` button in the top right. Once created, copy the Sid.
  * Deploy the application.
  * Press `Go to live application`.
  * You will see the start page. You can check for SNA transactions there, using the `Fetch transactions` button.
  * Copy the url and remove `index.html`, e.g. `verify-sna-xxxx.twil.io`. This will be the `sample backend URL` to use in the sample app.

<a name='UsingSampleApp'></a>

## Using the sample app

**To validate a phone number:**

- Set the phone number
  - Available carriers during this phase:
    - US - Verizon, TMO
    - UK - EE, Vodafone, O2 and ThreeUK
    - CA - Bell, Rogers and Telus
- Set the country code (only US during pilot stage)
- Set your [sample backend URL](#running-the-sample-backend)
- Submit the form by using the CTA button

**Expected behavior:**
The app will ask the network carrier if the provided phone number is the same used on the network request, if the phone number is correct, then the app will redirect to a success screen.

<a name='Logger'></a>

## Logger

---

The SDK includes a Logger utility to help with debugging and troubleshooting. You can use it to capture logs during SNA verification attempts.

```swift
import TwilioVerifySNA

// Start a new logging session (clears previous logs)
Logger.startNewSession()

// Your SNA verification code here
// ...

// Retrieve all logs as a string
let logs = Logger.getText()
print(logs)  // or display in your UI, send to your backend, etc.
```

### Available Methods

```swift
// Clear existing logs and start a new session
static func startNewSession()

// Get all logs collected in the current session as a single string
static func getText() -> String
```

<a name='Errors'></a>

## Errors

---

### Cellular Connection errors

See `CellularConnection+Models.swift`

<table>
  <tr>
    <th>Name</th>
    <th>Description</th>
    <th>Technical cause</th>
  </tr>
  <tr>
    <td>invalidURL</td>
    <td>Invalid URL</td>
    <td>URL is invalid or cannot be processed</td>
  </tr>
  <tr>
    <td>connectionFailed</td>
    <td>Connection failed: [error]</td>
    <td>Connection establishment failed</td>
  </tr>
  <tr>
    <td>redirectionFailed</td>
    <td>Redirection failed: [error]</td>
    <td>Indicates that a redirection attempt failed and returned an error</td>
  </tr>
  <tr>
    <td>requestFailed</td>
    <td>Request failed: [error]</td>
    <td>Request transmission or processing failed</td>
  </tr>
  <tr>
    <td>invalidResponse</td>
    <td>Invalid response</td>
    <td>Received response is invalid or cannot be parsed</td>
  </tr>
  <tr>
    <td>httpResponseParsingFailed</td>
    <td>HTTP response parsing failed</td>
    <td>HTTP response parsing encountered an error</td>
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
                case .cellularNetworkNotAvailable: return
                case .requestError(let cause):
                        switch cause {
                            case .instanceNotFound: return
                            case .invalidUrl: return
                            case .noResultFromUrl: return
                            case .networkingError(let error):
                                switch error {
                                    case .invalidURL: return
                                    case .connectionFailed(let error): return
                                    case .redirectionFailed(let error): return
                                    case .requestFailed(let error): return
                                    case .invalidResponse: return
                                    case .httpResponseParsingFailed: return
                                }
                        }
                }
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
          let errorDescription = cause.localizedDescription
    }
}
```

## Privacy Manifest

This document serves as the Privacy Manifest for the Twilio Verify SNA SDK. It outlines the privacy practices implemented in this SDK, providing a comprehensive understanding of how we handle data and respect user privacy.

### Purpose

The primary purpose of this Privacy Manifest is to facilitate developers and organizations in providing Apple with detailed information about the privacy practices employed within this SDK.

### Usage

To use this Privacy Manifest, simply refer to the relevant sections when you need to provide information to Apple or any other interested parties about the privacy practices used in this SDK.

### [Privacy Manifest](Sources/PrivacyInfo.xcprivacy)

<a name='Contributing'></a>

## Contributing

---

This project welcomes contributions. Please check out our [Contributing guide](./CONTRIBUTING.md) to learn more on how to get started.

<a name='License'></a>

## License

[Apache © Twilio Inc.](./LICENSE)
