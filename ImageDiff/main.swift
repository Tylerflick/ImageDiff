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
    fatalError("Arguments mismatch. Two input image paths, one output image path, c to specify CPU based or m to specify Metal based")
}
if !fileExists(path: arguments[1]) || !fileExists(path: arguments[2]) {
    fatalError("Input file(s) do not exist")
}

print("Starting up ImageDiff")
let start = Date()
var differ : Differ
if arguments[4] == "m" {
    differ = MetalDiffer()
} else if arguments[4] == "s" {
    differ = SoftwareDiffer()
} else {
    differ = CoreImageDiffer()
}

var diffs = differ.applyDiff(to: arguments[1], second: arguments[2], output: arguments[3])
let runtime = start.timeIntervalSinceNow
print("Total runtime (seconds): \(abs(runtime))")
exit(diffs)
