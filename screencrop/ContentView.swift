//
//  ContentView.swift
//  screencrop
//
//  Created by ekaansh arora on 20/02/22.
//

import SwiftUI
import PhotosUI

extension UIImage {
    func pixelData() -> ([UInt8]?, CGFloat?, CGFloat?) {
        let size = self.size
        let dataSize = size.width * size.height * 4
        var pixelData = [UInt8](repeating: 0, count: Int(dataSize))
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: &pixelData,
                                width: Int(size.width),
                                height: Int(size.height),
                                bitsPerComponent: 8,
                                bytesPerRow: 4 * Int(size.width),
                                space: colorSpace,
                                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
        guard let cgImage = self.cgImage else { return (nil, nil, nil) }
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))

        return (pixelData, size.width, size.height)
    }
 }

struct ContentView: View {
    @State private var showingImagePicker = false
    @State private var done = false
    @State private var firstLaunch = true
    @State private var inputImage: UIImage? = nil
    @State private var image: Image?
    @State private var result: UIImage?
    func loadImage() {
        firstLaunch = false
        done = false
        guard let inputImage = inputImage else { return }
        result = cropImg(inputImg: inputImage)
    }
    
    func save() {
        UIImageWriteToSavedPhotosAlbum(result!, nil, nil, nil)
        done = true
    }

    var body: some View {
        Text("open image")
            .padding()
            .onTapGesture {
                showingImagePicker = true
            }
            .onChange(of: inputImage) { _ in loadImage() }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $inputImage)
            }
        image?
            .resizable()
            .scaledToFit()
        if (result != nil) {
            Image(uiImage: result!)
                .resizable()
                .scaledToFit()
            Button("save image", action: save)
            if (done) {
                Text("saved")
            }
        } else if (!firstLaunch) {
            Text("working")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
