//
//  CoreImageDiffer.swift
//  ImageDiff
//
//  Created by Tyler Hoeflicker on 7/20/17.
//  Copyright © 2017 Tyler Hoeflicker. All rights reserved.
//

import Foundation
import CoreImage
import AppKit

class CoreImageDiffer : NSObject, Differ {
    
    func applyDiff(to first: String, second: String, output: String) {
        if #available(OSX 10.13, *) {
            let url = Bundle.main.url(forResource: "default", withExtension: "metallib")
            let data = try! Data(contentsOf: url!)
            let kernel = try! CIColorKernel(functionName: "simpleDiff", fromMetalLibraryData: data)
            
            let first = CIImage(contentsOf: URL(fileURLWithPath: first), options:[kCIImageApplyOrientationProperty: true])
            let second = CIImage(contentsOf: URL(fileURLWithPath: second), options:[kCIImageApplyOrientationProperty: true])
            
            let outputImage = kernel.apply(withExtent: (first?.extent)!, arguments: [first!, second!])
            
            if !writeCGImage(outputImage as! CGImage, toPath: NSURL.fileURL(withPath: output)) {
                fatalError("writing output to file \(output) failed")
            }
        } else {
            let kernelString = """
                            kernel vec4 simpleDiff(__sample first, __sample second) {
                                const vec4 same = vec4(255, 255, 255, 255);
                                const vec4 diff = vec4(0, 0, 0, 255);
                                const vec4 colorAtPixel = (first[0] != second[0] || first[1] != second[1] ||
                                first[2] != second[2] || first[3] != second[3]) ? diff : same;
                                return colorAtPixel;
                            }
                            """
            let kernel = CIColorKernel(string: kernelString)
            
            let first = CIImage(contentsOf: URL(fileURLWithPath: first))
            let second = CIImage(contentsOf: URL(fileURLWithPath: second))
            
            let outputImage = kernel?.apply(withExtent: (first?.extent)!, arguments: [first!, second!])
            let outputUrl = NSURL.fileURL(withPath: output)
            let out = NSBitmapImageRep(ciImage: outputImage!).cgImage
            
                
            if !writeCGImage(out!, toPath: outputUrl) {
                fatalError("writing output to file \(output) failed")
            }
        }
    }
}
