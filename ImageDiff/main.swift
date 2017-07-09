//
//  main.swift
//  ImageDiff
//
//  Created by Tyler Hoeflicker on 7/6/17.
//  Copyright © 2017 Tyler Hoeflicker. All rights reserved.
//

import Foundation
import MetalKit

func fileExists(path: String) -> Bool {
    return FileManager.default.fileExists(atPath: path)
}

let arguments = CommandLine.arguments

if arguments.count < 5 {
    fatalError("Fatal Error (arguments mismatch): two input image paths, one output image path, c to specify CPU based or m to specify Metal based")
}
if !fileExists(path: arguments[1]) || !fileExists(path: arguments[2]) {
    fatalError("Fatal Error: input file(s) do not exist")
}

print("Starting up ImageDiff")
let start = Date()
let differ = ImageDiffer()
if arguments[4] == "m" {
    differ.applyDiffWithMetal(to: arguments[1], second: arguments[2], output: arguments[3])
} else {
    differ.applyDiffWithCpu(to: arguments[1], second: arguments[2], output: arguments[3])
}
let runtime = start.timeIntervalSinceNow
print("Total runtime (seconds): \(abs(runtime))")
