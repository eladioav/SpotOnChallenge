//
//  APICaller.swift
//  SpotOnChallenge
//
//  Created by Eladio Alvarez Valle on 5/2/19.
//  Copyright © 2019 Eladio Alvarez Valle. All rights reserved.
//

import Foundation

enum HttpMethodType : String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case HEAD = "HEAD"
}

enum AuthenticationType {
    case None
    case Basic
    case OAuth2
}

public class API_Caller {
    
    
    var url : String
    var username : String?
    var password : String?
    var httpMethod : HttpMethodType
    var authentication : AuthenticationType
    
    //Completion Handler function
    typealias CompletionHandler = (_ statusCode : String, _ data : AnyObject?, _ response : URLResponse?) -> Void
    
    ///Access token class
    private lazy var accessToken : AccessToken = {
        
        return AccessToken.sharedInstance
        
    }()
    
    /// Class designated initializer
    ///
    /// - Parameters:
    ///     - url: URL of the API to call out
    ///     - httpMethodType : Http Method (GET,POST)
    ///     - authenticationType : Type of Authentication to call out service
    ///     - username: Credential's user name (optional)
    ///     - password: Credential's password (optional)
    /// - Returns: Void
    init(URL : String, httpMethodType : HttpMethodType, authenticationType : AuthenticationType, username : String? = nil, password : String? = nil) {
        
        self.url = URL
        self.httpMethod = httpMethodType
        self.authentication = authenticationType
        self.username = username
        self.password = password
    }
    
    /// Create Authorization header parameter
    ///
    /// - Parameters:
    ///     - username : User Name
    ///     - password : Password
    ///     - authenticationType : Type of Authentication
    /// - Returns: String of the authorization parameter
    func createAuthorization(username : String?, password : String?, authenticationType : AuthenticationType, handler : @escaping (Bool, String, String)->() ) {
        
        //Setup base 64 encoded credentials
        var loginString : NSString
        var loginData : Data
        var base64LoginString : String
        
        switch authenticationType {
            
        case .Basic :
            
            if username != nil && password != nil {
                //Basic Authorization with user and password
                loginString = NSString(format: "%@:%@", username!, password!)
                loginData = loginString.data(using: String.Encoding.utf8.rawValue)!
                base64LoginString = loginData.base64EncodedString(options: NSData.Base64EncodingOptions.lineLength64Characters)
                handler(true, "OK", "Basic \(base64LoginString)")
                
            } else if username != nil && password == nil{
                //Basic Authorization just User
                handler(true, "OK" ,  username!)
                
            } else {
                
                handler(true, "OK",  "")
            }
            
        case .OAuth2 :
            
            self.accessToken.checkTokenExpiration() {
                
                (isOk, errorMessage, accessToken) in //(isOk : Bool, errorMessage : String , accessToken : String)
                
                if isOk {
                    
                    handler(isOk, errorMessage, accessToken)
                    
                } else {
                    
                    handler(isOk, errorMessage, "")
                }
            }
            
        default :
            
            handler(true, "",  "")
        }
        
    }
    
    
    /// Call out an API and returns result via Closure
    ///
    /// - Parameters:
    ///     - dataParameter: Data to send to the server
    ///     - customHeaders : Custom header parameters [key:value]
    ///     - completionHandler: Closure that receives the server response (status code : String,data received : Any?, server response : URLResponse)
    /// - Returns: Void
    func callAPI(dataParameter : [String : Any]?, customHeaders : [String : String]?, completionHandler : @escaping CompletionHandler) -> Void {
        
        //Data to send to API, parsed
        var dataParsed : AnyObject?
        
        //Initialize session
        let session = URLSession.shared
        
        //Set Request for URL
        let request = NSMutableURLRequest(url: URL(string: self.url)!)
        
        //Check if there are parameters to send
        if let dataParameter_ = dataParameter {
            
            do {
                dataParsed = try JSONSerialization.data(withJSONObject: dataParameter_, options: .prettyPrinted) as AnyObject?
                
            }catch {
                dataParsed = nil
            }
        }
        
        //Set Request
        request.httpMethod = self.httpMethod.rawValue
        request.httpBody = dataParsed as? Data
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.value(forHTTPHeaderField: "")
        
        //Set custom headers
        if let customHeaders_ = customHeaders {
            
            for (key,value) in customHeaders_ {
                
                request.addValue(value, forHTTPHeaderField: key)
            }
        }
        
        //Set Authorization Header
        if self.authentication != .None {
            
            createAuthorization(username: self.username, password: self.password, authenticationType: self.authentication) {
                
                (isOk, errorMessage, accessToken) in
                
                if isOk { // authorization User created successfully
                    
                    request.setValue( accessToken , forHTTPHeaderField: "Authorization")
                    
                    //Initialize task for getting data
                    self.initializeTask(session: session, request: request as URLRequest) {
                        
                        (errorCode, data, response) in
                        
                        completionHandler(errorCode, data, nil)
                    }
                    
                    
                } else { //Couldn't create authorization user, or could not fetch it from Authorization server
                    
                    completionHandler(errorMessage,nil, nil)
                }
                
                
            }
            
        } else { // Session with not authorization Header
            
            //Initialize task for getting data
            self.initializeTask(session: session, request: request as URLRequest) {
                
                (errorCode, data, response) in
                
                completionHandler(errorCode, data, response)
            }
            
        }
        
        
    } //End func callAPI
    
    /// Start task and sent server response via handler
    /// - Parameters:
    ///     - session : Session that handle the request
    ///     - request : URL request
    ///     - completionHandler : escaping
    func initializeTask(session : URLSession , request : URLRequest, completionHandler : @escaping CompletionHandler) {
        
        //Initialize task for getting data
        let task = session.dataTask(with: request as URLRequest) {
            
            (data, response, error) in
            
            //Check for a successful response
            guard (error == nil) else {
                
                DispatchQueue.main.async {
                    () -> Void in
                    
                    completionHandler((error?.localizedDescription)!,nil, response)
                }
                
                return
            }
            
            //Did we get a successful 2XX Response?
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode , (statusCode >= 200 && statusCode <= 299) else {
                
                //Catch 403 code, to update access token
                if self.authentication == .OAuth2 && (response as? HTTPURLResponse)?.statusCode == 403 {
                    
                    //Update access token
                    self.accessToken.updateAccessToken() {
                        
                        (status,message) in
                        
                        completionHandler(message, nil, response)
                    }
                }
                
                if let response = response as? HTTPURLResponse {
                    
                    DispatchQueue.main.async {
                        () -> Void in
                        
                        completionHandler(response.statusCode.description,nil, response)
                    }
                } else if response != nil {
                    
                    DispatchQueue.main.async {
                        () -> Void in
                        
                        completionHandler("406",nil, response)
                    }
                    
                } else {
                    
                    DispatchQueue.main.async {
                        () -> Void in
                        
                        completionHandler("406",nil, response)
                    }
                }
                
                return
                
            }// End let status code
            
            //Was there any data returned?
            guard let data = data else {
                
                DispatchQueue.main.async {
                    () -> Void in
                    
                    //No data was returned
                    completionHandler(statusCode.description,nil, response)
                }
                return
            }
            
            //Sent data (not parsed)
            DispatchQueue.main.async {
                () -> Void in
                
                //Sent parsed data or nil
                completionHandler(statusCode.description,data as AnyObject?, response)
            }
            
            
            
        } // End let task
        
        //Resume (execute) task
        task.resume()
        
    }
    
} //End Class API_Caller

class AccessToken {
    
    static let sharedInstance = AccessToken()
    let defaults = UserDefaults.standard
    let authorizationServerURL = ""
    let userNameAuthorizationServer = ""
    let passwordAuthorizationServer = ""
    
    var tokenType : String?
    var scope : String?
    
    var accessToken : String? {
        
        didSet {
            
            defaults.set(accessToken, forKey: "accessToken")
        }
        
    }
    
    var expiresIn : Double = 0 {
        
        didSet {
            
            self.accessTokenExpirationDate = NSDate().timeIntervalSince1970 + expiresIn
        }
    }
    
    private var accessTokenExpirationDate : Double = 0 {
        
        didSet {
            
            defaults.set(accessTokenExpirationDate, forKey: "accessTokenExpirationDate")
        }
    }
    
    
    
    private lazy var apiCaller : API_Caller! = {
        
        let apiCaller_ = API_Caller(URL: authorizationServerURL, httpMethodType: .POST, authenticationType: .Basic, username: userNameAuthorizationServer, password: passwordAuthorizationServer)
        return apiCaller_
        
    }()
    
    private init() {
        
        //  Get values from NSUser Default
        self.accessToken = defaults.string(forKey: "accessToken")
        self.accessTokenExpirationDate = defaults.double(forKey: "accessTokenExpirationDate")
    }
    
    /// Get access token from Authorization Server
    private func getAccessToken(handler : @escaping(Bool,String)->() ) {
        
        apiCaller.callAPI(dataParameter: nil, customHeaders: nil) {
            
            (statusCode, data, response) in
            
            if statusCode == "200" { //Successful call
                
                do {
                    //Parse JSON from data received from server
                    let parsedResult = try JSONSerialization.jsonObject(with: (data as! Data?)!, options: .allowFragments)
                    
                    if let authorizationResponse = parsedResult as? [String : Any] {
                        
                        //Get access Token
                        if let accessToken_ = authorizationResponse["access_token"] as? String {
                            
                            self.accessToken = "Bearer " + accessToken_
                            
                        } else {
                            print("Access Token : No access token")
                            self.accessToken = nil
                            handler(false,"No Access token")
                            return // Exit function
                        }
                        
                        //Get expires in (seconds)
                        if let expiresIn_ = authorizationResponse["expires_in"] as? Double {
                            
                            self.expiresIn = expiresIn_
                            
                        } else {
                            print("Access Token : No expiration interval")
                            self.expiresIn = 0
                            handler(false,"No expiration interval")
                            return // Exit function
                        }
                        
                        //Get token type
                        if let tokenType_ = authorizationResponse["token_type"] as? String {
                            
                            self.tokenType = tokenType_
                            
                        } else {
                            
                            self.tokenType = nil
                        }
                        
                        
                        
                        //Get scope
                        if let scope_ = authorizationResponse["scope"] as? String {
                            
                            self.scope = scope_
                            
                        } else {
                            
                            self.scope = nil
                        }
                        
                        //No error getting parameters
                        handler(true,"OK")
                        
                    }
                    
                } catch {
                    
                    self.accessToken = nil
                    self.tokenType = nil
                    self.expiresIn = 0
                    self.scope = nil
                    print("Access Token : Error parsing result from Authorization server")
                    handler(false,"Error parsing result from Authorization server")
                }
                
                
            } else { //Call Error
                
                self.accessToken = nil
                self.tokenType = nil
                self.expiresIn = 0
                self.scope = nil
                print("Access Token : Error from authorization server : \(statusCode)")
                handler(false,"Error from authorization server : \(statusCode)")
            }
        }
    }
    
    /// Check if access token is valid
    /// - Parameters:
    ///     - handler : (isOk : Bool, errorMessage : String , accessToken : String)
    /// Returns : Seconds to token to expire
    func checkTokenExpiration(handler : @escaping(Bool, String, String)->() ) {
        
        let dateDiff = self.accessTokenExpirationDate - NSDate().timeIntervalSince1970 // Saved date - Today (in seconds)
        
        if dateDiff > 0 { //Token is still active
            
            print("Access Token : Active \(dateDiff) seconds : token : \(self.accessToken ?? "noToken")")
            handler(true, "OK",  self.accessToken == nil ? "" : self.accessToken!) //Return access token
            
        } else { //Token not active
            
            // Get access token from server
            self.getAccessToken() {
                
                (status,message) in
                
                if status { //Response is ok
                    
                    print("Access Token : Fetch token \(self.accessToken == nil ? "" : self.accessToken!) : \(self.accessTokenExpirationDate) secs")
                    handler(status, message, self.accessToken == nil ? "" : self.accessToken!) //Return access token
                    
                } else { //Error calling Authorization server
                    
                    print("Access Token : Error calling Authorization server")
                    handler(status, message,  "") //Return false,""
                }
            }
        }
        
        
    }
    
    /// Update Access Token directly
    func updateAccessToken(handler : @escaping(Bool,String)->()) {
        
        // Get access token from server
        self.getAccessToken() {
            
            (status,message) in
            
            if status { //Response is ok
                
                print("Access Token : OK updating Access token")
                handler(status, message)
                
            } else { //Error calling Authorization server
                
                print("Access Token : Error updating Access token")
                handler(status, message)
            }
        }
        
    }
    
}
