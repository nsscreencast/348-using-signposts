//
//  SignpostLog.swift
//  SignpostDemo
//
//  Created by Ben Scheirman on 8/2/18.
//  Copyright © 2018 NSScreencast. All rights reserved.
//

import Foundation
import os.log

struct SignpostLog {
    static var pointsOfInterest = OSLog(subsystem: "com.ficklebits.SignpostDemo", category: .pointsOfInterest)
    static var general: OSLog {
        if ProcessInfo.processInfo.environment.keys.contains("SIGNPOST_ENABLED") {
            return OSLog(subsystem: "com.ficklebits.SignpostDemo", category: "general")
        } else {
            return .disabled
        }
    }
    static var json = OSLog(subsystem: "com.ficklebits.SignpostDemo", category: "json")
}
