//
//  Differ.swift
//  ImageDiff
//
//  Created by Tyler Hoeflicker on 7/20/17.
//  Copyright © 2017 Tyler Hoeflicker. All rights reserved.
//

import Foundation

protocol Differ {
    func applyDiff(to first: String, second: String, output: String)
}
