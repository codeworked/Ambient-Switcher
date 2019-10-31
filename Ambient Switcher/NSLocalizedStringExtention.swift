//
//  NSLocalizedStringExtention.swift
//  Ambient Switcher
//
//  Created by Александр Гелета on 31.10.2019.
//  Copyright © 2019 Александр Гелета. All rights reserved.
//

import Foundation
import Cocoa

extension String {
    /// Takes localized string for current language from
    /// project localized strings files.
    ///
    /// Usage is very lean and simple:
    ///
    /// ```
    ///     "yourLocalizedString".localized()
    /// ```
    ///
    /// - Parameter bundle: Current application bundle. By default it is set to .main.
    /// - Parameter tableName: Collection of localized string. By default it is set to "Main".
    ///
    /// - Returns: Returns NSLocalizedString from localized collection. If localized string didn't
    /// found then will be returned it's name.
    func localized(bundle: Bundle = .main, tableName: String = "Main") -> String {
        return NSLocalizedString(self, tableName: tableName, value: "**\(self)**", comment: "")
    }
}
