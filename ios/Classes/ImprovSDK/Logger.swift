//
//  Logger.swift
//  Improv-iOS
//
//  Created by Bruno Pantaleão on 03/07/2024.
//  Modified by MrLiuYunPing on 2026-03-18 for improv_wifi_flutter.
//  Changes include explicit iOS availability declarations and safer
//  subsystem fallback handling for package redistribution.
//

import Foundation

import OSLog

@available(iOS 14.0, *)
extension Logger {
    /// Using your bundle identifier is a great way to ensure a unique identifier.
    private static let subsystem = Bundle.main.bundleIdentifier ?? "org.cocoapods.improv-wifi-flutter"

    static let main = Logger(subsystem: subsystem, category: "main")
}
