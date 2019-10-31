//
//  LightSensorManager.swift
//  Ambient Switcher
//
//  Created by Александр Гелета on 30.10.2019.
//  Copyright © 2019 Александр Гелета. All rights reserved.
//

import Foundation
import OSLog

/// Enumerates error which can be occured
/// while working with LightSensorManager.
enum LMUError: Error {
    /// Occures when Apple LMU controller
    /// can't be physicaly accessed.
    case couldNotGetSensor(String)
    /// Occures when Apple LMU controller
    /// initialized but we can't read data from it.
    case couldNotReadSensor(String)
}

/// Provides lux types.
enum AmbientLightType: Int {
    case night = 1
    case shadow = 2
    case sun = 3
}

/// Provides access to data from Apple LMU
/// controller on motherboard.
class LightSensorManager: NSObject {
    private var _dataPort: io_connect_t;
    private var _useNormalizedLuxValues: Bool;
    private let _notificationCenter: NotificationCenter
    private var _allowContinuous: Bool;
    
    private let _minNightLux: Int = 0
    private let _maxNightLux: Int = 8000
    private let _minShadowLux: Int = 8001
    private let _maxShadowLux: Int = 64999
    private let _minSunLux: Int = 65000
    private let _maxSunLux: Int = 160000
    
    private var _state = AmbientLightType.sun {
        didSet {
            self.stateDidChange()
        }
    }
    
    /// Initializes a new instance of subject.
    ///
    /// - Parameter dataPort: Port number on which Apple LMU controller can be
    /// accessed. Default value will be correct in most cases.
    /// - Parameter useNormalizedLuxValues: Use this for taking lux values
    /// divided by 10 to get good precision.
    ///
    /// - Returns: An instance of subject.
    init(dataPort: io_connect_t = 0, useNormalizedLuxValues: Bool = true, notificationCenter: NotificationCenter = .default) {
        self._dataPort = dataPort
        self._useNormalizedLuxValues = useNormalizedLuxValues
        self._notificationCenter = notificationCenter
        self._allowContinuous = false
    }
    
    /// Port number on which Apple LMU controller can be
    /// accessed. Now this is current port.
    var dataPort: io_connect_t {
        return self._dataPort;
    }
    
    /// Ambient lux value arround your Mac.
    var ambientLuxRatio: Int {
        var lux: Int = 0
        
        do {
            try lux = self.getLux(useNormalizedValues: self._useNormalizedLuxValues)
        } catch LMUError.couldNotGetSensor {
            os_log("Can't get LMU controller device.", log: OSLog.userFlow, type: .error)
        } catch LMUError.couldNotReadSensor {
            os_log("Can't read data from LMU controller device. MacBooks with Tachbar doesn't support.", log: OSLog.userFlow, type: .error)
        } catch let error {
            os_log("%{PUBLIC}@", log: OSLog.userFlow, type: .error, error.localizedDescription)
        }

        return lux
    }
    
    func stateDidChange() -> Void {
        switch self._state {
        case .night:
            self._notificationCenter.post(name: .nightOccured, object: nil)
        case .shadow:
            self._notificationCenter.post(name: .shadowOccured, object: nil)
        case .sun:
            self._notificationCenter.post(name: .sunOccured, object: nil)
        }
    }
    
    public func getLuxContinuous(qualityOfService: DispatchQoS.QoSClass = .userInitiated) -> Void {
        self._allowContinuous = true
        
        DispatchQueue.global(qos: qualityOfService).async {
            while (self._allowContinuous) {
                let lux = self.ambientLuxRatio
                    //debugPrint("raw lux: \(lux)")
                    
                if (lux >= self._minNightLux && lux < self._maxNightLux) {
                    self._state = .night
                    debugPrint(lux)
                }
                
                if (lux > self._minShadowLux && lux < self._maxShadowLux) {
                    self._state = .shadow
                    debugPrint(lux)
                }
                
                if (lux > self._minSunLux && lux < self._maxSunLux) {
                    self._state = .sun
                    debugPrint(lux)
                }
                
                sleep(1)
            }
        }
    }
    
    public func stopContinuousReading() -> Void {
        self._allowContinuous = false
    }
    
    /// Read lux data from Apple LMU controller.
    ///
    /// - Warning: This will not work with MacBook Pros with Tuchbar.
    ///
    /// - Parameter useNormalizedValues: If it is set to true then normilized lux values
    /// will be returned.
    ///
    /// - Throws: `LMUError.couldNotGetSensor` if it can't get access to Apple LMU controller on the motherboard.
    ///           `LMUError.couldNotReadSensor` if it can't read lux data but Apple LMU controller already initialized.
    ///
    /// - Returns: Returns lux values from Apple LMU controller.
    private func getLux(useNormalizedValues: Bool = true) throws -> Int {
        guard let serviceType = IOServiceMatching("AppleLMUController") else {
            throw LMUError.couldNotGetSensor("Can't get LMU controller")
        }
        
        let service = IOServiceGetMatchingService(kIOMasterPortDefault, serviceType)
        defer {
            IOObjectRelease(service)
        }
        
        guard IOServiceOpen(service, mach_task_self_, 0, &self._dataPort) == KERN_SUCCESS else {
            throw LMUError.couldNotReadSensor("Can't read data from LMU controller")
        }
        
        setbuf(stdout, nil)
        
        var outputs: UInt32 = 2
        let values = UnsafeMutablePointer<UInt64>.allocate(capacity: Int(outputs))
        let zero: UnsafeMutablePointer<Int> = UnsafeMutablePointer<Int>.allocate(capacity: 8)
        
        guard IOConnectCallMethod(self._dataPort, 0, nil, 0, nil, 0, values, &outputs, nil, zero) == KERN_SUCCESS else {
            throw LMUError.couldNotReadSensor("Can't read data from LMU controller")
        }
        
        var currentLux = Int(values[0])
        if (useNormalizedValues) {
            currentLux /= 10
        }
        
        return currentLux
    }
}

extension Notification.Name {
    /// Occures when current lux value is in night range.
    static var nightOccured: Notification.Name {
        return .init(rawValue: "LightSensorManager.nightOccured")
    }
    
    /// Occures when current lux value is in shadow range.
    static var shadowOccured: Notification.Name {
        return .init(rawValue: "LightSensorManager.shadowOccured")
    }
    
    /// Occures when current lux value is in sun range.
    static var sunOccured: Notification.Name {
        return .init(rawValue: "LightSensorManager.sunOccured")
    }
}
