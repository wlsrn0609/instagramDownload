/*

 inhibit_all_warnings!
 
 pod 'Alamofire', '~> 4.7'
 
 
 */
import UIKit
import Alamofire

class Server: NSObject {
    
    
    static func postData(urlString:String, method : HTTPMethod = .post, otherInfo : [String:String]? = nil, completion : @escaping ( _ data  : Data? ) -> Void){
        guard let url = URL(string: urlString) else {
            return completion(nil)
        }
        
        Alamofire.request(url, method: method, parameters: otherInfo).responseData { (dataResponse:DataResponse) in
            if let error = dataResponse.error {
                print("error \(error.localizedDescription)")
                completion(nil)
            }else{
                if dataResponse.response?.statusCode == 200 {
                    completion(dataResponse.data)
                }else{
                    print("httpStatusCode \(String(describing: dataResponse.response?.statusCode))")
                    completion(nil)
                }
            }
        }
    }
    
}
