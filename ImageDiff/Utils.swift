//
//  Utils.swift
//  ImageDiff
//
//  Created by Tyler Hoeflicker on 7/20/17.
//  Copyright © 2017 Tyler Hoeflicker. All rights reserved.
//

import Foundation

public func writeCGImage(_ image: CGImage, toPath path: URL) -> Bool {
    guard let destination = CGImageDestinationCreateWithURL(path as CFURL, kUTTypePNG, 1, nil) else { return false }
    CGImageDestinationAddImage(destination, image, nil)
    return CGImageDestinationFinalize(destination)
}
