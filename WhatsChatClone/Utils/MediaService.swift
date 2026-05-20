import Foundation
import AVFoundation
import Photos
import UIKit

class MediaService {
    static let shared = MediaService()
    
    private init() {}
    
    func compressVideo(inputURL: URL, completion: @escaping (Data?) -> Void) {
        let exportURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
        let asset = AVAsset(url: inputURL)
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetMediumQuality) else {
            completion(nil)
            return
        }
        
        exportSession.outputURL = exportURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true
        
        exportSession.exportAsynchronously {
            if exportSession.status == .completed {
                let data = try? Data(contentsOf: exportURL)
                completion(data)
                try? FileManager.default.removeItem(at: exportURL)
            } else {
                completion(nil)
            }
        }
    }
    
    func saveToGallery(msg: Message) {
        if msg.messageType == "image", let data = msg.imageData, let image = UIImage(data: data) {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        } else if msg.messageType == "video", let videoData = msg.videoData {
            let tempPath = NSTemporaryDirectory() + UUID().uuidString + ".mp4"
            let fileURL = URL(fileURLWithPath: tempPath)
            
            do {
                try videoData.write(to: fileURL)
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)
                }) { success, _ in
                    try? FileManager.default.removeItem(at: fileURL)
                }
            } catch {
                print("Failed to write video data")
            }
        }
    }
}
