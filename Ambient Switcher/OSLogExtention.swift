//
//  OSLogExtention.swift
//  Ambient Switcher
//
//  Created by Александр Гелета on 30.10.2019.
//  Copyright © 2019 Александр Гелета. All rights reserved.
//

import Foundation
import OSLog

extension OSLog {
    private static var subsystem = Bundle.main.bundleIdentifier!
    
    /// Log provider for tracing UI events.
    static let viewCycle = OSLog(subsystem: subsystem, category: "viewCycle")
    /// Log provider for tracing events in user related code.
    static let userFlow = OSLog(subsystem: subsystem, category: "userFlow")
}
