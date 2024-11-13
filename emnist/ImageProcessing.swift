import UIKit
import CoreImage
import CoreVideo

func cropTransparency(image: UIImage) -> UIImage? {
    print("cropTransparency: İşleme başlandı")  // Hata ayıklama çıktısı
    
    guard let cgImage = image.cgImage else {
        print("cropTransparency: cgImage yok")
        return nil
    }

    let width = cgImage.width
    let height = cgImage.height
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    var pixelData = [UInt8](repeating: 0, count: width * height * 4)

    guard let context = CGContext(data: &pixelData,
                                  width: width,
                                  height: height,
                                  bitsPerComponent: 8,
                                  bytesPerRow: 4 * width,
                                  space: colorSpace,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
        print("cropTransparency: CGContext oluşturulamadı")
        return nil
    }
    context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

    for i in stride(from: 0, to: pixelData.count, by: 4) {
        if pixelData[i] > 200 {
            pixelData[i] = 255
            pixelData[i + 1] = 255
            pixelData[i + 2] = 0
            pixelData[i + 3] = 0
        }
    }

    guard let processedCGImage = context.makeImage() else {
        print("cropTransparency: İşlenmiş CGImage oluşturulamadı")
        return nil
    }
    let processedImage = UIImage(cgImage: processedCGImage)

    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 28, height: 28))
    let resizedImage = renderer.image { _ in
        UIColor.white.setFill()
        UIRectFill(CGRect(origin: .zero, size: CGSize(width: 28, height: 28)))
        processedImage.draw(in: CGRect(origin: .zero, size: CGSize(width: 28, height: 28)))
    }
    print("cropTransparency: İşlem başarıyla tamamlandı")  // Hata ayıklama çıktısı
    return resizedImage
}

extension UIImage {
    func toCVPixelBuffer(targetSize: CGSize = CGSize(width: 28, height: 28)) -> CVPixelBuffer? {
        print("toCVPixelBuffer: Başladı")  // Hata ayıklama çıktısı

        let ciImage = CIImage(image: self)?.applyingFilter("CIPhotoEffectMono")
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
        UIColor.white.setFill()
        UIRectFill(CGRect(origin: .zero, size: targetSize))

        if let ciImage = ciImage {
            let context = CIContext()
            if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
                UIImage(cgImage: cgImage).draw(in: CGRect(origin: .zero, size: targetSize))
            }
        }

        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        guard let finalImage = resizedImage?.cgImage else {
            print("toCVPixelBuffer: Görüntü yok")
            return nil
        }

        var pixelBuffer: CVPixelBuffer?
        let attributes: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue!,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue!
        ]
        CVPixelBufferCreate(kCFAllocatorDefault,
                            Int(targetSize.width),
                            Int(targetSize.height),
                            kCVPixelFormatType_OneComponent8,
                            attributes as CFDictionary,
                            &pixelBuffer)

        guard let buffer = pixelBuffer else {
            print("toCVPixelBuffer: PixelBuffer oluşturulamadı")
            return nil
        }

        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: Int(targetSize.width),
            height: Int(targetSize.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        )
        context?.draw(finalImage, in: CGRect(x: 0, y: 0, width: targetSize.width, height: targetSize.height))
        CVPixelBufferUnlockBaseAddress(buffer, .readOnly)

        print("toCVPixelBuffer: Başarıyla tamamlandı")  // Hata ayıklama çıktısı
        return buffer
    }
}
