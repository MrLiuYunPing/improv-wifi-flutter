//
//  Logger.swift
//  Improv-iOS
//
//  Created by Bruno Pantaleão on 03/07/2024.
//

import Foundation

import OSLog

@available(iOS 14.0, *)
extension Logger {
    /// Using your bundle identifier is a great way to ensure a unique identifier.
    private static let subsystem = Bundle.main.bundleIdentifier ?? "org.cocoapods.improv-wifi-flutter"

    static let main = Logger(subsystem: subsystem, category: "main")
}
