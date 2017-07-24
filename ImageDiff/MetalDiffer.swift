
//  ImageDiffer.swift
//  ImageDiff
//
//  Created by Tyler Hoeflicker on 7/6/17.
//  Copyright © 2017 Tyler Hoeflicker. All rights reserved.
//

import Foundation
import Metal
import MetalKit

class MetalDiffer : NSObject, Differ {
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
    
    public func applyDiff(to first: String, second: String, output: String) {
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
        
        let w = pipelineState.threadExecutionWidth
        let h = pipelineState.maxTotalThreadsPerThreadgroup / w
        let threadsPerThreadgroup = MTLSizeMake(h, w, 1)
        let threadgroupsPerGrid = MTLSize(width: (self.outTexture.width + w - 1) / w,
                                          height: (self.outTexture.height + h - 1) / h,
                                          depth: 1)
        
        commandEncoder?.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        commandEncoder?.endEncoding()
        
        commandBuffer?.commit()
        commandBuffer?.waitUntilCompleted()
        let image = self.createImage(from: self.outTexture)
        if !writeCGImage(image, toPath: NSURL.fileURL(withPath: output)) {
            fatalError("writing output to file \(arguments[2]) failed")
        }
    }
    
    private func setUpMetal() {
        if let kernelFunction = defaultLibrary.makeFunction(name: "kernel_metalDiff") {
            do {
                pipelineState = try device.makeComputePipelineState(function: kernelFunction)
            }
            catch {
                fatalError("Impossible to setup Metal")
            }
        }
    }
    
    private func createTexture(from image: NSImage) -> MTLTexture {
        
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
    
    private func createTexture(from width: Int, height: Int, pixelFormat: MTLPixelFormat) -> MTLTexture {
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat, width: width, height: height, mipmapped: false)
        return self.device.makeTexture(descriptor: textureDescriptor)!
    }
    
    private func createImage(from texture: MTLTexture) -> CGImage {
        
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
}

