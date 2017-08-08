
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
    var diffCount: [UInt] = [0]
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
        let diffCntBuffer = device.makeBuffer(bytes: &diffCount, length: (diffCount.count * MemoryLayout<UInt>.size), options: [])
        commandEncoder?.setBuffer(diffCntBuffer, offset: 0, index: 0)
        
        let threadsPerThreadgroup = MTLSizeMake(16, 16, 1)
        let threadgroupsPerGrid = MTLSizeMake(Int(self.outTexture.width) / threadsPerThreadgroup.width, Int(self.outTexture.height) / threadsPerThreadgroup.height, 1)
        
        commandEncoder?.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        commandEncoder?.endEncoding()
        
        commandBuffer?.commit()
        commandBuffer?.waitUntilCompleted()
        
        var sumOfDiff: UInt = 0
        let nsData = NSData(bytesNoCopy: (diffCntBuffer?.contents())!,
                            length: (diffCntBuffer?.length)!,
                            freeWhenDone: false)
        nsData.getBytes(&sumOfDiff, length:(diffCntBuffer?.length)!)
        
        if sumOfDiff > 0 {
            let image = self.createImage(from: self.outTexture)
            if !writeCGImage(image, toPath: NSURL.fileURL(withPath: output)) {
                fatalError("Fatal Error: Writing output to file \(arguments[2]) failed")
            }
        } else {
            print("No differences found")
        }
    }
    
    private func setUpMetal() {
        if let kernelFunction = defaultLibrary.makeFunction(name: "kernel_metalDiff") {
            do {
                pipelineState = try device.makeComputePipelineState(function: kernelFunction)
            }
            catch {
                fatalError("Fatal Error: Impossible to setup Metal")
            }
        }
    }
    
    private func createTexture(from image: NSImage) -> MTLTexture {
        
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            fatalError("Fatal Error: Can't open image \(image)")
        }
        
        let textureLoader = MTKTextureLoader(device: self.device)
        do {
            let textureOut = try textureLoader.newTexture(with: cgImage)
            return textureOut
        }
        catch {
            fatalError("Fatal Error: Can't load texture")
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

