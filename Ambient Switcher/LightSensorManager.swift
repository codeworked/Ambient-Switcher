//
//  LightSensorManager.swift
//  Ambient Switcher
//
//  Created by Александр Гелета on 30.10.2019.
//  Copyright © 2019 Александр Гелета. All rights reserved.
//

import Foundation
import OSLog

// MARK: Class

/// Provides access to data from Apple LMU
/// controller on motherboard.
class LightSensorManager: NSObject {
    /// Initializes a new instance of subject.
    ///
    /// - Parameter dataPort: Port number on which Apple LMU controller can be
    /// accessed. Default value will be correct in most cases.
    ///
    /// - Returns: An instance of subject.
    init(dataPort: io_connect_t = 0) {
        self.dataPort = dataPort
    }
    
    /// Port number on which Apple LMU controller can be
    /// accessed. Now this is current port.
    private(set) var dataPort: io_connect_t
    
    /// If it's set to true then getting lux values in background
    /// will be allowed.
    public var continuousEnabled: Bool = false
    
    /// Safely reads lux ratio from Apple LMU Sensor.
    ///
    /// - Returns: Value of type (Int, LuxType) where first value is raw lux and second is LuxType.
    public func getLuxOnce() -> (lux: Int, luxType: LuxType) {
        var rawLux = 0
        
        do {
            try rawLux = self.getRawLux(useNormalizedValues: true)
        } catch LMUError.couldNotGetSensor {
            os_log("Can't get LMU controller device.", log: OSLog.userFlow, type: .error)
        } catch LMUError.couldNotReadSensor {
            os_log("Can't read data from LMU controller device. MacBooks with Tachbar doesn't support.", log: OSLog.userFlow, type: .error)
        } catch let error {
            os_log("%{PUBLIC}@", log: OSLog.userFlow, type: .error, error.localizedDescription)
        }

        return (lux: rawLux, luxType: .parse(rawLux: rawLux))
    }
    
    /// Works in background and reads Apple LMU controller lux data.
    ///
    /// - Warning: This methods will work only if continuousEnabled is set to true.
    ///
    /// - Parameter qualityOfService: Allows developer to choose which QoS mode will be used for background read task. By default it is set to DispatchQoS.QoSClass.userInitiated.
    /// - Parameter dataRead: Clojure executing every time when data was read from Apple LMU controller.
    /// - Parameter luxValue: Contains current data read from Apple LMU controller and parsed lux type from this data.
    public func getLuxContinuous(qualityOfService: DispatchQoS.QoSClass = .userInitiated, dataRead: @escaping (_ luxValue: (lux: Int, luxType: LuxType)) -> Void) -> Void {
        self.continuousEnabled = true
        
        DispatchQueue.global(qos: qualityOfService).async {
            while (self.continuousEnabled) {
                dataRead(self.getLuxOnce())
                sleep(1)
            }
        }
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
    public func getRawLux(useNormalizedValues: Bool = true) throws -> Int {
        var rawLux = 0
        
        try DispatchQueue.global(qos: .userInitiated).sync {
            guard let serviceType = IOServiceMatching("AppleLMUController") else {
                throw LMUError.couldNotGetSensor("Can't get LMU controller")
            }
            
            let service = IOServiceGetMatchingService(kIOMasterPortDefault, serviceType)
            defer {
                IOObjectRelease(service)
            }
            
            guard IOServiceOpen(service, mach_task_self_, 0, &self.dataPort) == KERN_SUCCESS else {
                throw LMUError.couldNotReadSensor("Can't read data from LMU controller")
            }
            
            setbuf(stdout, nil)
            
            var outputs: UInt32 = 2
            let values = UnsafeMutablePointer<UInt64>.allocate(capacity: Int(outputs))
            let zero: UnsafeMutablePointer<Int> = UnsafeMutablePointer<Int>.allocate(capacity: 8)
            
            guard IOConnectCallMethod(self.dataPort, 0, nil, 0, nil, 0, values, &outputs, nil, zero) == KERN_SUCCESS else {
                throw LMUError.couldNotReadSensor("Can't read data from LMU controller")
            }
            
            rawLux = Int(values[0])
            if (useNormalizedValues) {
                rawLux /= 10
            }
        }
        
        return rawLux
    }
}

// MARK: Exceptions

extension LightSensorManager {
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
}

// MARK: Lux type

/// Lux type ranges.
///
/// Example usage for sun:
/// ```
///     let sun = LuxType.sun.rawValue
///     let min = LuxType.sun.lowerBand
///     let max = LuxType.sun.upperBand
/// ```
enum LuxType {
    case night
    case shadow
    case sun
    
    var rawValue: (lowerBand: Int, upperBand: Int) {
        switch self {
        case .night:
            return (lowerBand: 0, upperBand: 8000)
        case .shadow:
            return (lowerBand: 8001, upperBand: 64999)
        case .sun:
            return (lowerBand: 65000, upperBand: 160000)
        }
    }
        
    init?(rawValue: (lowerBand: Int, upperBand: Int)) {
        switch rawValue {
        case (lowerBand: 0, upperBand: 8000):
            self = .night
        case (lowerBand: 8001, upperBand: 64999):
            self = .shadow
        case (lowerBand: 65000, upperBand: 160000):
            self = .sun
        default:
            return nil
        }
    }
    
    /// Parse LuxType from raw value loaded from LMU Sensor.
    ///
    /// - Parameter rawLux: Raw lux value from LMU Sensor.
    ///
    /// Example of usage:
    /// ```
    ///     let sensor = LightSensorManager()
    ///     let luxType = LuxType.parse(rawLux: sensor.getRawLux())
    /// ```
    static func parse(rawLux: Int) -> LuxType {
        var luxType: LuxType = .night
        
        if (rawLux.between(min: LuxType.night.rawValue.lowerBand, max: LuxType.night.rawValue.upperBand)) {
            luxType = .night
        }
        
        if (rawLux.between(min: LuxType.shadow.rawValue.lowerBand, max: LuxType.shadow.rawValue.upperBand)) {
            luxType = .shadow
        }
        
        if (rawLux.between(min: LuxType.sun.rawValue.lowerBand, max: LuxType.sun.rawValue.upperBand)) {
            luxType = .sun
        }
        
        return luxType
    }
}
