//
//  LoggerViewController.swift
//  TwilioVerifySNADemo
//
//  Created by Alejandro Orozco Builes on 11/01/24.
//

import UIKit
#if canImport(TwilioVerifySNA)
import TwilioVerifySNA
#endif

class LoggerViewController: UIViewController {

    // MARK: - IBoutlets

    @IBOutlet weak var loggerTextView: UITextView!
    @IBOutlet weak var copyButton: UIButton!

    // MARK: - Properties

    private var loggerText: String = ""

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        #if canImport(TwilioVerifySNA)
        loggerText = Logger.getText()
        #endif
        loggerTextView.text = loggerText
    }

    // MARK: - IBActions

    @IBAction func didTapCopyButton(_ sender: Any) {
        UIPasteboard.general.string = loggerText
    }
}
