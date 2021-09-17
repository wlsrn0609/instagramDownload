
import UIKit

import Photos

func saveVideo(urlString:String, complete:@escaping(_:Bool)->Void){
    Server.postData(urlString: urlString, method: .get) { kData in
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let filePath="\(documentsPath)/tempFile.mp4"
        if let data = kData {
            let fileURL = URL(fileURLWithPath: filePath)
            DispatchQueue.main.async {
                do {
                    try data.write(to: fileURL)
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)
                    }) { completed, error in
                        if let error = error {
                            print("Video Save Fail:\(error.localizedDescription)")
                            complete(false); return
                        }else if completed {
                            complete(true)
                            print("Video is saved!")
                        }
                    }
                } catch {
                    complete(false); return
                }
            }
        }
    }
}

//let videoImageUrl = "http://www.sample-videos.com/video/mp4/720/big_buck_bunny_720p_1mb.mp4"
//
//DispatchQueue.global(qos: .background).async {
//    if let url = URL(string: urlString),
//        let urlData = NSData(contentsOf: url) {
//        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0];
//        let filePath="\(documentsPath)/tempFile.mp4"
//        DispatchQueue.main.async {
//            urlData.write(toFile: filePath, atomically: true)
//            PHPhotoLibrary.shared().performChanges({
//                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: URL(fileURLWithPath: filePath))
//            }) { completed, error in
//                if completed {
//                    print("Video is saved!")
//                }
//            }
//        }
//    }
//}
