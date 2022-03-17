import Foundation
import UIKit
import SwiftUI

extension UIImage {
    func pixelData() -> [UInt8]? {
        let size = self.size
        var pixelData = [UInt8](repeating: 0, count: Int(size.width * size.height * 4))
        let context = CGContext(data: &pixelData, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: 4 * Int(size.width), space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
        context?.draw(self.cgImage!, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        return pixelData
    }
    
    func scaleImage(toSize newSize: CGSize) -> UIImage? {
        var newImage: UIImage?
        let newRect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height).integral
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        if let context = UIGraphicsGetCurrentContext(), let cgImage = self.cgImage {
            context.interpolationQuality = .high
            let flipVertical = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: newSize.height)
            context.concatenate(flipVertical)
            context.draw(cgImage, in: newRect)
            if let img = context.makeImage() {
                newImage = UIImage(cgImage: img)
            }
            UIGraphicsEndImageContext()
        }
        return newImage
    }
}

public struct RGBAPixel {
    public init( rawVal : UInt32  ) {
        raw = rawVal
    }
    public init( r: UInt8, g:UInt8, b:UInt8) {
        raw = 0xFF000000 | UInt32(r) | UInt32(g)<<8 | UInt32(b)<<16
    }
    public init( uiColor: UIColor ) {
        var r: CGFloat = 0.0;
        var g: CGFloat = 0.0;
        var b: CGFloat = 0.0;
        var alpha: CGFloat = 0.0;
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &alpha)
        
        self.init(r: UInt8(r*255), g: UInt8(g*255), b: UInt8(b*255))
    }
    
    public var raw: UInt32
    public var red: UInt8 {
        get { return UInt8(raw & 0xFF) }
        set { raw = UInt32(newValue) | (raw & 0xFFFFFF00) }
    }
    public var green: UInt8 {
        get { return UInt8( (raw & 0xFF00) >> 8 ) }
        set { raw = (UInt32(newValue) << 8) | (raw & 0xFFFF00FF) }
    }
    public var blue: UInt8 {
        get { return UInt8( (raw & 0xFF0000) >> 16 ) }
        set { raw = (UInt32(newValue) << 16) | (raw & 0xFF00FFFF) }
    }
    public var alpha: UInt8 {
        get { return UInt8( (raw & 0xFF000000) >> 24 ) }
        set { raw = (UInt32(newValue) << 24) | (raw & 0x00FFFFFF) }
    }
    

    
    
}

open class MyImage {
    let pixels: UnsafeMutableBufferPointer<RGBAPixel>
    let height: Int;
    let width: Int;
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo: UInt32 = CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
    let bitsPerComponent = 8
    let bytesPerRow: Int

    public init( width: Int, height: Int ) {
        self.height = height
        self.width = width
        bytesPerRow = 4 * width
        let rawdata = UnsafeMutablePointer<RGBAPixel>.allocate(capacity: width * height)
        pixels = UnsafeMutableBufferPointer<RGBAPixel>(start: rawdata, count: width * height)
    }

    public init( image: UIImage ) {
        height = Int(image.size.height)
        width = Int(image.size.width)
        bytesPerRow = 4 * width
        
        let rawdata = UnsafeMutablePointer<RGBAPixel>.allocate(capacity: width * height)
        let imageContext = CGContext(data: rawdata, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo)
        imageContext?.draw(image.cgImage!, in: CGRect(origin: CGPoint.zero, size: image.size));
        
        pixels = UnsafeMutableBufferPointer<RGBAPixel>(start: rawdata, count: width * height)
    }
    
    open func getPixel( _ x: Int, y: Int ) -> RGBAPixel {
        return pixels[x+y*width];
    }

    open func setPixel( _ value: RGBAPixel, x: Int, y: Int )  {
        pixels[x+y*width] = value;
    }
    
    
    open func toUIImage() -> UIImage {
        let outContext = CGContext(data: pixels.baseAddress, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo, releaseCallback: nil, releaseInfo: nil)
        return UIImage(cgImage: outContext!.makeImage()!)
    }
    
    open func transformPixels( _ tranformFunc: (RGBAPixel)->RGBAPixel ) -> MyImage {
        let newImage = MyImage(width: self.width, height: self.height)
        for y in 0 ..< height {
            for x in 0 ..< width {
                let p1 = getPixel(x, y: y)
                let p2 = tranformFunc(p1)
                newImage.setPixel(p2, x: x, y: y)
            }
        }
        return newImage
    }
}

func checkThreshold (pixel: RGBAPixel) -> Bool {
    let threshold = 230
    if(pixel.red > threshold && pixel.blue > threshold && pixel.green > threshold) {
        return true
    }
    else {return false}
}

func cropImg (inputImg: UIImage) -> UIImage {
    let ui = inputImg.scaleImage(toSize: CGSize(width: inputImg.size.width / 4, height: inputImg.size.height / 4))
    let img = MyImage(image: ui!)
    let centreLine = Int((ui?.size.height)!) / 2
    var cropY1 = Int((ui?.size.height)!)
    var cropY2 = 0
    

    outerLoop: for y in Int(centreLine)..<Int((ui?.size.height)!) {
        var lengthOfBox = 0
        for x in 0..<Int((ui?.size.width)!) {
            let pixel = img.getPixel(x, y: y)
            if(checkThreshold(pixel: pixel)) {
                lengthOfBox += 1
            }
            if(lengthOfBox > (Int((ui?.size.width)! * 0.95))) {
                cropY1 = y
                break outerLoop
            }
        }
    }

outerLoop2: for y in (0...Int(centreLine)).reversed() {
        var lengthOfBox = 0
        for x in 0..<Int((ui?.size.width)!) {
            let pixel = img.getPixel(x, y: y)
            if(checkThreshold(pixel: pixel)) {
                lengthOfBox += 1
            }
            if(lengthOfBox > (Int((ui?.size.width)! * 0.95))) {
                cropY2 = y
                break outerLoop2
            }
        }
    }
//    let res = ui?.cgImage?.cropping(to: CGRect(x: 0, y: cropY2, width: Int((ui?.size.width)!), height: (cropY1 - cropY2)))
    let upres = inputImg.cgImage!.cropping(to: CGRect(x: 0, y: (cropY2 + 1) * 2, width: Int((inputImg.size.width)), height: 2 * (cropY1 - (cropY2 + 1))))
    print(cropY1, cropY2)
    return  UIImage(cgImage: upres!)
}
