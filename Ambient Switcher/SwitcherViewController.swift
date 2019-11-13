//
//  SwitcherViewController.swift
//  Ambient Switcher
//
//  Created by Александр Гелета on 30.10.2019.
//  Copyright © 2019 Александр Гелета. All rights reserved.
//

import Cocoa

class SwitcherViewController: NSViewController {
    @IBOutlet weak var lightTypeLabel: NSTextField!
    @IBOutlet weak var lightStrengthIndicator: NSLevelIndicator!
    @IBOutlet weak var modeSwitcherButton: NSSegmentedControl!
    
    @IBAction func modeSwitcherButtonAction(_ sender: Any) {
        switch self.modeSwitcherButton.selectedSegment {
        case 0:
            UIThemeSwitcher.switchTheme(theme: .LightTheme)
            self.autoSwitch = false
            break;
        case 1:
            UIThemeSwitcher.switchTheme(theme: .DarkTheme)
            self.autoSwitch = false
            break;
        case 2:
            self.autoSwitch = true
        default:
            break;
        }
    }
    
    @IBAction func quitButtonAction(_ sender: Any) {
        NSApplication.shared.terminate(self)
    }
    
    private let sensorManager: LightSensorManager = LightSensorManager()
    private var autoSwitch: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sensorManager.getLuxContinuous(dataRead: {(luxData: (lux: Int, luxType: LuxType)) -> Void in
            switch luxData.luxType {
            case .night:
                DispatchQueue.main.async {
                    self.lightStrengthIndicator.integerValue = 1
                    self.lightTypeLabel.stringValue = "lightTypeLabel.stringValue.night".localized()
                }
                if (self.autoSwitch) {
                    UIThemeSwitcher.switchTheme(theme: .DarkTheme)
                }
                break
            case .shadow:
                DispatchQueue.main.async {
                    self.lightStrengthIndicator.integerValue = 2
                    self.lightTypeLabel.stringValue = "lightTypeLabel.stringValue.shadow".localized()
                }
                if (self.autoSwitch) {
                    UIThemeSwitcher.switchTheme(theme: .DarkTheme)
                }
                break
            case .sun:
                DispatchQueue.main.async {
                    self.lightStrengthIndicator.integerValue = 3
                    self.lightTypeLabel.stringValue = "lightTypeLabel.stringValue.sun".localized()
                }
                if (self.autoSwitch) {
                    UIThemeSwitcher.switchTheme(theme: .LightTheme)
                }
                break
            }
        })
    }
}

extension SwitcherViewController {
  static func freshController() -> SwitcherViewController {
    let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
    let identifier = NSStoryboard.SceneIdentifier("SwitcherViewController")
    guard let viewcontroller = storyboard.instantiateController(withIdentifier: identifier) as? SwitcherViewController else {
      fatalError("Why cant i find SwitcherViewController? - Check Main.storyboard")
    }
    
    return viewcontroller
  }
}
