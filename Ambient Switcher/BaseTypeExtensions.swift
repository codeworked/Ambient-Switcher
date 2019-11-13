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

extension Int {
    /// Checks if value in range of min and max passed values.
    ///
    /// - Parameter min: Minimum range band.
    /// - Parameter max: Maximum range band.
    /// - Parameter orEqual: If it is set to true then __>__ and __<__ will be changed to __>=__ and __<=__ in compare code.
    ///
    /// - Returns: True if value in range between min and max.
    ///
    /// Usage example:
    /// ```
    ///     var logic = 25.between(min: 10, max: 40) // true
    /// ```
    ///
    public func between(min: Int, max: Int, orEqual: Bool = false) -> Bool {
        if (orEqual) {
            return self >= min && self <= max
        }
        
        return self > min && self < max
    }
}
