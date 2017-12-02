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
    
    func applyDiff(to first: String, second: String, output: String) -> Int32 {
//        if #available(OSX 10.13, *) {
//            let url = Bundle.main.url(forResource: "default", withExtension: "metallib")
//            let data = try! Data(contentsOf: url!)
//            // TODO: Figuire out why this isn't loading
//            let kernel = try! CIColorKernel(functionName: "simpleDiff", fromMetalLibraryData: data)
//
//            let first = CIImage(contentsOf: URL(fileURLWithPath: first), options:[kCIImageApplyOrientationProperty: true])
//            let second = CIImage(contentsOf: URL(fileURLWithPath: second), options:[kCIImageApplyOrientationProperty: true])
//
//            let outputImage = kernel.apply(extent: (first?.extent)!, arguments: [first!, second!])
//
//            if !writeCGImage(outputImage as! CGImage, toPath: NSURL.fileURL(withPath: output)) {
//                fatalError("Writing output to file \(output) failed")
//            }
//            return 0
//        } else {
            return applyDiffWithCIKL(to: first, second: second, output: output)
//        }
    }
    
    func applyDiffWithCIKL(to first: String, second: String, output: String) -> Int32 {
        let kernelString = """
                            kernel vec4 naiveDiff(__sample first, __sample second) {
                                const vec4 same = vec4(255, 255, 255, 255);
                                const vec4 diff = vec4(0, 0, 0, 255);
                                return (first.r != second.r || first.g != second.g || first.b != second.b || first.a != second.a) ? diff : same;
                            }
                            """
        let kernel = CIColorKernel(source: kernelString)
        
        let first = CIImage(contentsOf: URL(fileURLWithPath: first))
        let second = CIImage(contentsOf: URL(fileURLWithPath: second))
        
        let outputImage = kernel?.apply(extent: (first?.extent)!, arguments: [first!, second!])!
        let outputUrl = NSURL.fileURL(withPath: output)
        let out = convertCIImageToCGImage(inputImage: outputImage!)
        
        
        if !writeCGImage(out!, toPath: outputUrl) {
            fatalError("Writing output to file \(output) failed")
        }
        return 0
    }
    
    func convertCIImageToCGImage(inputImage: CIImage) -> CGImage! {
        let context = CIContext(options: nil)
        return context.createCGImage(inputImage, from: inputImage.extent)
    }
}
