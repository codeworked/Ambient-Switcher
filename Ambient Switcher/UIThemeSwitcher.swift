//
//  UIThemeSwitcher.swift
//  Ambient Switcher
//
//  Created by Александр Гелета on 30.10.2019.
//  Copyright © 2019 Александр Гелета. All rights reserved.
//

import Foundation
import OSLog

/// Enumerates UI theme mode specified in macOS by Apple.
/// It provides LightTheme and DarkTheme aliases to String value
/// of Bool type for inserting it to AppleScript which will swich
/// dark mode option.
enum UITheme: String {
    /// Take this if you want disable macOS dark mode.
    case LightTheme = "false"
    /// Take this if you want enable macOS dark mode.
    case DarkTheme = "true"
}

/// Provides functionality to programmaticaly switch
/// macOS dark mode.
class UIThemeSwitcher {
    /// Sets macOS dark mode to enabled or disabled.
    ///
    /// Usage is very simple and intuitive.
    ///
    /// ```
    ///     UIThemeSwitcher.switchTheme(theme: .LightTheme)
    ///     UIThemeSwitcher.switchTheme(theme: .DarkTheme)
    /// ```
    ///
    /// - Warning: Because of Apple doesn't allow us to manipulate System Events from
    /// code then we are using AppleScript calling with NSAppleScript. And this may cause
    /// to problems. And if something goes wrong you should read system log for process
    /// __Ambient Switcher__ and category __userFlow__.
    ///
    /// # Used this AppleScript
    ///
    /// ```AppleScript
    ///     tell application "System Events"
    ///         tell appearance preferences
    ///             set dark mode to <true/false>
    ///         end tell
    ///     end tell
    /// ```
    ///
    /// - Parameter theme: Theme that will be applied.
    static func switchTheme(theme: UITheme) -> Void {
        // Theme will note be switched if it is already enabled.
        // In that case we just returning from function.
        let mode = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light";
        if ((mode == "Dark" && theme == .DarkTheme) || (mode == "Light" && theme == .LightTheme)) {
            return;
        }
        
        os_log("Switching UI dark mode to: %{PUBLIC}@", log: OSLog.userFlow, type: .info, theme.rawValue)
        
        let source = """
            tell application "System Events"
                tell appearance preferences
                    set dark mode to \(theme.rawValue)
                end tell
            end tell
        """
        
        // I don't know why but if we want to execute AppleScript
        // from application code we need to do it in Swift queue
        // dispatcher asynchronously.
        DispatchQueue.global(qos: .userInitiated).async {
            let executionResult = NSAppleScript(source: source)?.executeAndReturnError(nil).stringValue ?? "success"
            
            if (executionResult != "success") {
                os_log("An error occured during execution of %{PUBLIC}@.", log: OSLog.userFlow, type: .error, source)
            }
        }
    }
}
