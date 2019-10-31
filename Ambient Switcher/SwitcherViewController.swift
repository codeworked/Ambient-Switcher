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
    
    private var _allowAutoSwitch: Bool = true
    
    @IBAction func modeSwitcherButtonAction(_ sender: Any) {
        switch self.modeSwitcherButton.selectedSegment {
        case 0:
            UIThemeSwitcher.switchTheme(theme: .LightTheme)
            self._allowAutoSwitch = false
            break;
        case 1:
            UIThemeSwitcher.switchTheme(theme: .DarkTheme)
            self._allowAutoSwitch = false
            break;
        case 2:
            self._allowAutoSwitch = true
        default:
            break;
        }
    }
    
    @IBAction func quitButtonAction(_ sender: Any) {
        NSApplication.shared.terminate(self)
    }
    
    private let notificationCenter = NotificationCenter.default
    private let _lightSensor: LightSensorManager = LightSensorManager.init(dataPort: 0, useNormalizedLuxValues: true)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.notificationCenter.addObserver(self, selector: #selector(nightOccured), name: .nightOccured, object: nil)
        
        self.notificationCenter.addObserver(self, selector: #selector(shadowOccured), name: .shadowOccured, object: nil)
        
        self.notificationCenter.addObserver(self, selector: #selector(sunOccured), name: .sunOccured, object: nil)
        
        self._lightSensor.getLuxContinuous()
    }
    
    @objc private func nightOccured(_ notification: Notification) {
        DispatchQueue.main.async {
            self.lightTypeLabel.stringValue = "Night"
            self.lightStrengthIndicator.integerValue = 1
            
            if (self._allowAutoSwitch) {
                UIThemeSwitcher.switchTheme(theme: .DarkTheme)
            }
        }
    }
    
    @objc private func shadowOccured(_ notification: Notification) {
        DispatchQueue.main.async {
            self.lightTypeLabel.stringValue = "Shadow"
            self.lightStrengthIndicator.integerValue = 2
            
            if (self._allowAutoSwitch) {
                UIThemeSwitcher.switchTheme(theme: .DarkTheme)
            }

        }
    }
    
    @objc private func sunOccured(_ notification: Notification) {
        DispatchQueue.main.async {
            self.lightTypeLabel.stringValue = "Sun"
            self.lightStrengthIndicator.integerValue = 3
            
            if (self._allowAutoSwitch) {
                UIThemeSwitcher.switchTheme(theme: .LightTheme)
            }

        }
    }
    
}

extension SwitcherViewController {
  // MARK: Storyboard instantiation
  static func freshController() -> SwitcherViewController {
    //1.
    let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
    //2.
    let identifier = NSStoryboard.SceneIdentifier("SwitcherViewController")
    //3.
    guard let viewcontroller = storyboard.instantiateController(withIdentifier: identifier) as? SwitcherViewController else {
      fatalError("Why cant i find SwitcherViewController? - Check Main.storyboard")
    }
    return viewcontroller
  }
}
