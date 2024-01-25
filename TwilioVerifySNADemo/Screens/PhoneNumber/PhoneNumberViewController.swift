//
//  PhoneNumberViewController.swift
//  TwilioVerifySNADemo
//
//  Copyright © 2022 Twilio.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import UIKit
import TwilioVerifySNA
import SNANetworking
import CoreTelephony

final class PhoneNumberViewController: UIViewController {

    // MARK: - IBOutlets

    @IBOutlet private var appVersionLabel: UILabel!
    @IBOutlet private var backendUrlTextField: UITextField!
    @IBOutlet private var phoneNumberTextField: UITextField!
    @IBOutlet private var phoneCountryCodeTextField: UITextField!
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!

    // MARK: - Properties

    /**
     Required for your implementation:
     SDK instance, we strongly recommend to lazy load the SDK,
     in the best practices you will probably create
     this instance on your ViewModel/Presenter or logic layer
     */
    private lazy var twilioVerify: TwilioVerifySNA = TwilioVerifySNABuilder.build()

    /**
     Network layer to communicate with the backend: (not required for your SDK implementation)
     In the best practices you probably call networking operations from your viewModel/presenter/worker
     */
    private lazy var networkLayer = NetworkLayer()

    // MARK: - View Controller life cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        /*
         Methods `configureUI` and `retrieveSavedInput`and gesture recognizer are not required for the SDK to work.
         These methods accomplish the demo showcase.
         */

        configureUI()
        retrieveSavedInput()

        view.addGestureRecognizer(
            UITapGestureRecognizer(
                target: self,
                action: #selector(dismissKeyboard)
            )
        )
    }

    @IBAction func didTapOnLoggerButton(_ sender: Any) {
        performSegue(
            withIdentifier: Segues.loggerViewScreen.rawValue,
            sender: nil
        )
    }
    
    @IBAction private func submitButtonAction() {
        /*
         Let's validate the user input is not empty.
         */
        guard let phoneNumber = phoneNumberTextField.text, !phoneNumber.isEmpty,
              let backendUrl = backendUrlTextField.text, !backendUrl.isEmpty,
              let phoneCountryCode = phoneCountryCodeTextField.text else {

            // Let's notify the user that some data is missing.
            showGenericError("Missing country code, phone number or backend URL.")
            return
        }

        /*
         Recommended: validate if the user does have a working sim card
         */
        guard hasCellularCoverage() else {
            /*
             Let's notify the user that the sim card is missing.
             For real world use cases you probably would use a secondary
             verification method instead of showing an error.
             */
            showGenericError("For silent network authentication, you will need a working sim card.")
            return
        }

        // Shows the loader
        toggleLoader()

        // Demo purposes: we save the given data for a further testing session, so it autocompletes the text fields
        saveInput(
            phoneNumber: phoneNumber,
            phoneCountryCode: phoneCountryCode,
            backendUrl: backendUrl
        )

        // Backend requires a E.164 phone number, so we prepare it by
        // appending the country code and number in the same string.
        let completePhoneNumber = phoneCountryCode.appending(phoneNumber)

        // Lets start a user verification by requesting it to our custom backend (that will call Twilio Verify services)

        Logger.startNewSession()

        startVerification(
            phoneNumber: completePhoneNumber,
            backendUrl: backendUrl
        ) { [weak self] snaUrl in

            /*
             With the SNAURL retrieved, we have to make sure that the data
             exists and it's not empty
             */
            guard let snaUrl = snaUrl, !snaUrl.isEmpty else {

                // If error:

                // 1. Hide loader
                self?.toggleLoader()

                // 2. Notify the user that something went wrong
                self?.showGenericError("Unable to get SNA URL from backend.")

                return
            }

            // if the SNAURL is valid, we have to use TwilioVerifySDK to process the url
            self?.processUrl(
                snaUrl: snaUrl,
                phoneNumber: completePhoneNumber,
                backendUrl: backendUrl
            )
        }
    }

    private func processUrl(
        snaUrl: String,
        phoneNumber: String,
        backendUrl: String
    ) {
        /*
         With the given phone number, country code, backend url and SNAURL
         we ask the SDK to process the url. What the SDK is doing is to take
         care of all the redirections and is making sure that all the requests are done via cellular network.
         */

        twilioVerify.processURL(
            snaUrl
        ) { [weak self] result in

            guard let self = self else { return }

            /*
             We have to handle the SDK result,
             if the result contains any error we should behave on the `.failure` scenario.
             */

            switch result {
                case .success:
                    /*
                     if the SDK correctly handled the URL, we have ask to the backend
                     if the validation was completed, we should not trust in any frontend results.
                     */
                    self.continueVerification(
                        phoneNumber: phoneNumber,
                        backendUrl: backendUrl
                    )

                case .failure(let error):
                    self.toggleLoader()
                    self.showGenericError(error.errorDescription)
            }
        }
    }

    private func continueVerification(
        phoneNumber: String,
        backendUrl: String
    ) {
        checkVerificationStatus(
            phoneNumber: phoneNumber,
            backendUrl: backendUrl
        ) { [weak self] success in

            guard let self = self else { return }

            self.toggleLoader()

            /*
             The SDK will always respond in a background thread, so it is highly recommended that we
             handle the response on the main thread if we are going to update the UI
             */

            DispatchQueue.main.async { [weak self] in
                guard success else {
                    // if the validation fails, you can customize your app the behavior here
                    self?.performSegue(
                        withIdentifier: Segues.verificationErrorScreen.rawValue,
                        sender: nil
                    )
                    return
                }

                // if the validation succeed, you can customize your app the behavior here
                self?.performSegue(
                    withIdentifier: Segues.verificationSuccessfulScreen.rawValue,
                    sender: nil
                )
            }
        }
    }

    private func startVerification(
        phoneNumber: String,
        backendUrl: String,
        onComplete: @escaping (_ snaUrl: String?) -> Void
    ) {
        let request = VerificationRequest(
            phoneNumber: phoneNumber
        )

        networkLayer.post(
            to: backendUrl.appending(Endpoints.startVerification.rawValue),
            request: request
        ) { (response: VerificationResponse?) in

            guard let response = response else {
                return onComplete(nil)
            }

            onComplete(response.snaUrl)
        }
    }

    private func checkVerificationStatus(
        phoneNumber: String,
        backendUrl: String,
        onComplete: @escaping (_ success: Bool) -> Void
    ) {
        let request = VerificationRequest(
            phoneNumber: phoneNumber
        )

        networkLayer.post(
            to: backendUrl.appending(Endpoints.checkVerification.rawValue),
            request: request
        ) { (response: VerificationResult?) in

            guard let response = response else {
                return onComplete(false)
            }

            onComplete(response.success)
        }
    }
}

/**
 In this extension are all the properties and methods that provide this demo extra functionalities,
 please notice that these are not required in your SDK implementation.
 */
extension PhoneNumberViewController {
    /// Segues used for transitions
    private enum Segues: String {
        case verificationSuccessfulScreen
        case verificationErrorScreen
        case loggerViewScreen
    }

    /**
     Custom backend endpoints:
     If you create your own backend using a Twilio template, this endpoints will be used
     for your validations, otherwise you should use your own backend implementation
     */
    private enum Endpoints: String {
        case startVerification = "/verify-start"
        case checkVerification = "/verify-check"
    }

    /// Constants used for saving user input (not required for your SDK implementation)
    private enum KeysForUserDefaults: String {
        case phoneNumber
        case phoneCountryCode
        case backendUrl
    }

    /// Not required for the SDK implementation.
    private func toggleLoader() {
        DispatchQueue.main.async {
            self.activityIndicator.isAnimating ?
            self.activityIndicator.stopAnimating() :
            self.activityIndicator.startAnimating()

            self.phoneNumberTextField.isEnabled = !self.activityIndicator.isAnimating
            self.phoneCountryCodeTextField.isEnabled = !self.activityIndicator.isAnimating
            self.backendUrlTextField.isEnabled = !self.activityIndicator.isAnimating
        }
    }

    /// Not required for the SDK implementation.
    private func showGenericError(_ error: String? = nil) {
        DispatchQueue.main.async { [weak self] in
            let alert = UIAlertController(
                title: "Error",
                message: error ?? "Unexpected error",
                preferredStyle: .alert
            )

            alert.addAction(UIAlertAction(title: "Accept", style: .cancel))
            self?.present(alert, animated: true)
        }
    }

    /// Not required for the SDK implementation.
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    /// Not required for the SDK implementation.
    private func configureUI() {
        let borderColor = UIColor(red: 0.533, green: 0.569, blue: 0.667, alpha: 1)
        let textColor = UIColor(red: 0.294, green: 0.337, blue: 0.443, alpha: 1)
        let placeholderSize: CGFloat = 14

        [phoneNumberTextField, phoneCountryCodeTextField, backendUrlTextField].forEach {
            $0?.attributedPlaceholder = NSAttributedString(
                string: $0?.placeholder ?? String(),
                attributes: [
                    .foregroundColor: textColor,
                    .font: UIFont(
                        name: "Inter-Regular",
                        size: placeholderSize
                    ) ?? .systemFont(ofSize: placeholderSize)
                ]
            )
            $0?.layer.borderColor = borderColor.cgColor
        }

        /// Only used for reference
        appVersionLabel.text = "\(appVersionLabel.text ?? "") | SDK: \(TwilioVerifySNAConfig.version) | SAMPLE: \(sampleAppVersion)"
    }

    /// Not required for the SDK implementation.
    private func retrieveSavedInput() {
        phoneNumberTextField.text = UserDefaults.standard.string(
            forKey: KeysForUserDefaults.phoneNumber.rawValue
        )

        phoneCountryCodeTextField.text = UserDefaults.standard.string(
            forKey: KeysForUserDefaults.phoneCountryCode.rawValue
        ) ?? "+1"

        backendUrlTextField.text = UserDefaults.standard.string(
            forKey: KeysForUserDefaults.backendUrl.rawValue
        )
    }

    /// Not required for the SDK implementation.
    private func saveInput(
        phoneNumber: String,
        phoneCountryCode: String,
        backendUrl: String
    ) {
        UserDefaults.standard.set(
            phoneNumber,
            forKey: KeysForUserDefaults.phoneNumber.rawValue
        )

        UserDefaults.standard.set(
            phoneCountryCode,
            forKey: KeysForUserDefaults.phoneCountryCode.rawValue
        )

        UserDefaults.standard.set(
            backendUrl,
            forKey: KeysForUserDefaults.backendUrl.rawValue
        )
    }

    /// Not required for the SDK implementation.
    private func hasCellularCoverage() -> Bool {
        let networkInfo = CTTelephonyNetworkInfo()
        let carriers = networkInfo.serviceSubscriberCellularProviders ?? [:]

        let validCarriers = carriers.values.compactMap {
            $0.isoCountryCode
        }

        return !validCarriers.isEmpty
    }
}

/// Not required for the SDK implementation.
private let sampleAppVersion = "0.0.5"
