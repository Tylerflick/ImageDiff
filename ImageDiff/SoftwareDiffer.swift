//
//  SoftwareDiffer.swift
//  ImageDiff
//
//  Created by Tyler Hoeflicker on 7/20/17.
//  Copyright © 2017 Tyler Hoeflicker. All rights reserved.
//

import Foundation
import AppKit

class SoftwareDiffer : NSObject, Differ {
    
    public func applyDiff(to first: String, second: String, output: String) {
        guard let firstImage = NSImage(byReferencingFile: first) else {
            fatalError("Image \(first) does not exist")
        }
        guard let secondImage = NSImage(byReferencingFile: second) else {
            fatalError("Image \(second) does not exist")
        }
        
        if (firstImage.size != secondImage.size) {
            fatalError("Input image sizes must match")
        }
        
        let imageOne = firstImage.cgImage(forProposedRect: nil, context: nil, hints: nil)
        let imageTwo = secondImage.cgImage(forProposedRect: nil, context: nil, hints: nil)
        
        let dataOne = imageOne?.dataProvider!.data
        let dataTwo = imageTwo?.dataProvider!.data
        
        let bufferOneRange = CFRangeMake(0,CFDataGetLength(dataOne))
        let bufferTwoRange = CFRangeMake(0,CFDataGetLength(dataTwo))
        
        if bufferOneRange.length != bufferTwoRange.length {
            fatalError("Fatal Error: Image buffer lengths must match")
        }
        
        var bufferOne = [UInt8](repeating: 0, count: Int(bufferOneRange.length))
        var bufferTwo = [UInt8](repeating: 0, count: Int(bufferTwoRange.length))
        var bufferOut = [UInt8](repeating: 0, count: Int(bufferOneRange.length))
        
        CFDataGetBytes(dataOne, bufferOneRange, &bufferOne)
        CFDataGetBytes(dataTwo, bufferTwoRange, &bufferTwo)
        
        var i = 0
        while i < bufferOneRange.length {
            if bufferOne[i] != bufferTwo[i] || bufferOne[i + 1] != bufferTwo[i + 1] || bufferOne[i + 2] != bufferTwo[i + 2] || bufferOne[i + 3] != bufferTwo[i + 3] {
                bufferOut[i] = 0;
                bufferOut[i + 1] = 0;
                bufferOut[i + 2] = 0;
                bufferOut[i + 3] = 255;
            } else {
                bufferOut[i] = 255;
                bufferOut[i + 1] = 255;
                bufferOut[i + 2] = 255;
                bufferOut[i + 3] = 255;
            }
            i += 4
        }
        
        let bitmapInfo = CGBitmapInfo(rawValue: (CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue))
        let context = CGContext(data: &bufferOut,
                                width: (imageOne?.width)!,
                                height: (imageOne?.height)!,
                                bitsPerComponent: (imageOne?.bitsPerComponent)!,
                                bytesPerRow: (imageOne?.bytesPerRow)!,
                                space: (imageOne?.colorSpace)!,
                                bitmapInfo: bitmapInfo.rawValue)
        
        let image = context!.makeImage()!
        if !writeCGImage(image, toPath: NSURL.fileURL(withPath: output)) {
            fatalError("Fatal Error: Writing output to file \(arguments[2]) failed")
        }
    }
}
