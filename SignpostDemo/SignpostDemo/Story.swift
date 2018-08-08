//
//  Story.swift
//  SignpostDemo
//
//  Created by Ben Scheirman on 7/27/18.
//  Copyright © 2018 NSScreencast. All rights reserved.
//

import Foundation

struct Story : Decodable {
    let id: Int
    let by: String
    let title: String
    let score: Int
    let time: Date
}
