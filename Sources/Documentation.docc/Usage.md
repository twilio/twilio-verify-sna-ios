# Usage

For using the SDK you can follow the next steps:

Import the SDK dependency, on your `.swift` file:

```swift
import TwilioVerifySNA
```

Instantiate the SDK

```swift
private lazy var twilioVerify: TwilioVerifySNA = TwilioVerifySNASession()
```

Process the SNA URL by calling the method:

```swift
func processURL(_ url: String, onComplete: @escaping ProcessURLResult)
```

```swift
twilioVerify.processURL(snaUrl) { result in
    switch result {
        case .success:
          // Handle success scenario

        case .failure(let error):
        // Handle error scenario
    }
}
```

Full implementation demonstration

```swift
import UIKit
import TwilioVerifySNA

class ViewController: UIViewController {
    private lazy var twilioVerify: TwilioVerifySNA = TwilioVerifySNASession()

     override func viewDidLoad() {
        super.viewDidLoad()
    }

    private func validateSNAURL() async {
        let urlFromBackend = await asyncMethodToGetSNAUrl()

        twilioVerify.processURL(snaUrl) { result in
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
