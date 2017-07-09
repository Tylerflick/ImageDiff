
//  ImageDiffer.swift
//  ImageDiff
//
//  Created by Tyler Hoeflicker on 7/6/17.
//  Copyright © 2017 Tyler Hoeflicker. All rights reserved.
//

import Foundation
import Metal
import MetalKit

class ImageDiffer : NSObject {
    /// A Metal device
    lazy var device: MTLDevice! = MTLCreateSystemDefaultDevice()
    
    /// A Metal library
    lazy var defaultLibrary: MTLLibrary! = {
        self.device.makeDefaultLibrary()
    }()
    
    /// A Metal command queue
    lazy var commandQueue: MTLCommandQueue! = {
        print("Using \(self.device.name)")
        return self.device.makeCommandQueue()
    }()
    
    var inTextureOne: MTLTexture!
    var inTextureTwo: MTLTexture!
    var outTexture: MTLTexture!
    let bytesPerPixel: Int = 4
    
    /// A Metal compute pipeline state
    var pipelineState: MTLComputePipelineState!
    
    public func setUpMetal() {
        if let kernelFunction = defaultLibrary.makeFunction(name: "kernel_simpleDiff") {
            do {
                pipelineState = try device.makeComputePipelineState(function: kernelFunction)
            }
            catch {
                fatalError("Impossible to setup Metal")
            }
        }
    }
    
    public func applyDiffWithCpu(to first: String, second: String, output: String) {
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
        if !self.writeCGImage(image, toPath: NSURL.fileURL(withPath: output)) {
            fatalError("Fatal Error: Writing output to file \(arguments[2]) failed")
        }
    }
    
    public func applyDiffWithMetal(to first: String, second: String, output: String) {
        setUpMetal()
        
        guard let firstImage = NSImage(byReferencingFile: first) else {
            fatalError("Fatal Error: Image \(first) does not exist")
        }
        guard let secondImage = NSImage(byReferencingFile: second) else {
            fatalError("Fatal Error: Image \(second) does not exist")
        }
        
        if (firstImage.size != secondImage.size) {
            fatalError("Fatal Error: Input image sizes must match")
        }
        
        self.inTextureOne = createTexture(from: firstImage)
        self.inTextureTwo = createTexture(from: secondImage)
        
        if (self.inTextureOne.pixelFormat != self.inTextureTwo.pixelFormat) {
            fatalError("Fatal Error: Input image pixel formats must match")
        }
        
        self.outTexture = createTexture(from: self.inTextureOne.width, height: self.inTextureOne.height, pixelFormat: MTLPixelFormat.rgba8Unorm)
        
        let commandBuffer = commandQueue.makeCommandBuffer()
        let commandEncoder = commandBuffer?.makeComputeCommandEncoder()
        commandEncoder?.setComputePipelineState(pipelineState)
        
        commandEncoder?.setTexture(inTextureOne, index: 0)
        commandEncoder?.setTexture(inTextureTwo, index: 1)
        commandEncoder?.setTexture(outTexture, index: 2)
        
        let threadGroupCount = MTLSizeMake(16, 16, 1)
        let threadGroups = MTLSizeMake(Int(self.outTexture.width) / threadGroupCount.width, Int(self.outTexture.height) / threadGroupCount.height, 1)
        
        commandEncoder?.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupCount)
        commandEncoder?.endEncoding()
        
        commandBuffer?.commit()
        commandBuffer?.waitUntilCompleted()
        let image = self.createImage(from: self.outTexture)
        if !self.writeCGImage(image, toPath: NSURL.fileURL(withPath: output)) {
            fatalError("writing output to file \(arguments[2]) failed")
        }
    }
    
    
    public func createTexture(from image: NSImage) -> MTLTexture {
        
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            fatalError("Can't open image \(image)")
        }
        
        let textureLoader = MTKTextureLoader(device: self.device)
        do {
            let textureOut = try textureLoader.newTexture(with: cgImage)
            return textureOut
        }
        catch {
            fatalError("Can't load texture")
        }
    }
    
    public func createTexture(from width: Int, height: Int, pixelFormat: MTLPixelFormat) -> MTLTexture {
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat, width: width, height: height, mipmapped: false)
        return self.device.makeTexture(descriptor: textureDescriptor)!
    }
    
    public func createImage(from texture: MTLTexture) -> CGImage {
        
        let imageByteCount = texture.width * texture.height * bytesPerPixel
        let bytesPerRow = texture.width * bytesPerPixel
        var src = [UInt8](repeating: 0, count: Int(imageByteCount))
        
        let region = MTLRegionMake2D(0, 0, texture.width, texture.height)
        texture.getBytes(&src, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)
        
        let bitmapInfo = CGBitmapInfo(rawValue: (CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue))
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitsPerComponent = 8
        let context = CGContext(data: &src,
                                width: texture.width,
                                height: texture.height,
                                bitsPerComponent: bitsPerComponent,
                                bytesPerRow: bytesPerRow,
                                space: colorSpace,
                                bitmapInfo: bitmapInfo.rawValue)
        
        return context!.makeImage()!
    }
    
    public func writeCGImage(_ image: CGImage, toPath path: URL) -> Bool {
        guard let destination = CGImageDestinationCreateWithURL(path as CFURL, kUTTypePNG, 1, nil) else { return false }
        CGImageDestinationAddImage(destination, image, nil)
        return CGImageDestinationFinalize(destination)
    }
}
