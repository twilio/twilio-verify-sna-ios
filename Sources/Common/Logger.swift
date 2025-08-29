//
//  Logger.swift
//  TwilioVerifySNA
//
//  Created by Alejandro Orozco Builes on 29/08/25.
//

import Foundation

public final class Logger {

    // MARK: - Properties

    // Array to store log entries during a session
    private static var logs: [String] = []

    // MARK: - Public Methods

    /// Start a new session by clearing existing logs
    public static func startNewSession() {
        logs.removeAll()
    }

    /// Record a log entry with time, line, and message
    public static func log(_ message: String, lineNumber: Int = #line) {
        let timestamp = Date()
        let logEntry = "\(timestamp) [Line \(lineNumber)]: \(message)"
        logs.append(logEntry)
    }

    /// Get all logs as a single string
    public static func getText() -> String {
        return logs.joined(separator: "\n")
    }
}
