//
//  WeatherModel.swift
//  Weather_APP (iOS)
//
//  Created by Lai Wei on 2021-04-05.
//

import Foundation
import UIKit


/** Callback function for the newwork request
 - parameter Data?: raw response object in data Format
 - parameter Error?: Error object, if the request is failed
 */

public typealias APICallback = (Data?, Error?, URLResponse?) -> Void


/// This is used to make the network request for all related APIs

open class APIRequest: NSObject, URLSessionDelegate{
    
    /// standard RESTFul API method
    public enum RequestMethod: String {
        
        case get = "GET"
        case post = "POST"
        case delete = "DELETE"
        case put = "PUT"
        case patch = "PATCH"
        
    }
    
    public enum ParameterFormat: String {
        
        case PathParameter = "PathParameter"
        case JSON = "JSON"
        case FormURLEncoded = "FormURLEncoded"
    }
    
    /// Pre-defined header fields, we can put the redefined values in the place.
    
    #if !targetEnvironment(macCatalyst)
    public var globalHeaders = ["device_id":"-", "device_os": "iOS_\(UIDevice.current.systemVersion)"]
    #else
    public var globalHeaders = ["device_id":"-", "device_os": "iOS_Mac_\(UIDevice.current.systemVersion)"]
    #endif
    
    /// default timeout for all the request in seconds
    public var defaultTimeout: Double = 60
    
    /// Apple build session manager for download
    var urlSessionManager: URLSession?
    
    /// indicate whether we want to ignore and disable the ssl certificate for the request
    var urlIgnoreSSLCertificate: Bool = false
    
    /// request queue to hold the request, and make the operation sequential
    var requestQueue = OperationQueue()
    
    public override init() {
        super.init()
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = defaultTimeout
        configuration.timeoutIntervalForResource = defaultTimeout
        urlSessionManager = URLSession(configuration: configuration, delegate: self as URLSessionDelegate, delegateQueue: requestQueue)
    }
    
    /// this is used to convert the data from the response to a json obejct
    public func object(_ data: Data) -> Any? {
        var obj: Any?
        do{
            obj = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
        }catch let error as NSError{
            print("json serialization error: \(error)")
        }
        return obj
    }
    
    private func requestRestAPI<T>(method: RequestMethod, path:String, params: T?, headers: [String: String]?, format:ParameterFormat = ParameterFormat.PathParameter, queue: DispatchQueue = DispatchQueue.global(), timeout:Double? = nil, callback: @escaping APICallback) -> T? {
            
            guard let url = URL(string: path) else {
                print("can not convert the path to url \(path)")
                callback(nil, nil, nil)
                return nil
            }
            
            // Prepare the headers for the request
            var request = URLRequest(url: url)
            for (key, value) in globalHeaders {
                request.addValue(value, forHTTPHeaderField: key)
            }
            if let reqHeaders = headers {
                for (key, value) in reqHeaders {
                    request.addValue(value, forHTTPHeaderField: key)
                }
            }
            
            // Prepare the request method
            var requestMethod = "GET"
            switch (method){
                case .delete:
                    requestMethod = "DELETE"
                case .patch:
                    requestMethod = "PATCH"
                case .post:
                    requestMethod = "POST"
                case .put:
                    requestMethod = "PUT"
                default:
                    requestMethod = "GET"
            }
            request.httpMethod = requestMethod
            
            // Prepare the body parameter or url path parameter
            var bodyData: Data? = nil
            switch(format){
                case .JSON:
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    if let paramVals = params {
                        do{
                            bodyData = try JSONSerialization.data(withJSONObject: paramVals, options: .prettyPrinted)
                        }catch{
                            print("can not convert the parameters to the proper body data.\(paramVals)")
                        }
                    }
                
                case .FormURLEncoded:
                    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                    if let keyValPair = params as? [String: Any] {
                        let result = keyValPair.map{ "\($0)=\($1)" }.joined(separator: "&")
                        bodyData = result.data(using: .utf8)
                    }
                
                case .PathParameter:
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    if let keyValPair = params as? [String: Any] {
                        let result = keyValPair.map{ "\($0)=\($1)" }.joined(separator: "&")
                        if result.count > 0 {
                            let newURL = path + "?" + result
                            request.url = URL(string: newURL)
                        }
                    }
            }
            request.httpBody  = bodyData
            if let bodyData = bodyData {
                request.setValue("\(bodyData.count)", forHTTPHeaderField: "Content-Length")
            }
            
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            
            if let tout = timeout {
                request.timeoutInterval = tout
            }else{
                request.timeoutInterval = defaultTimeout
                urlSessionManager?.configuration.timeoutIntervalForRequest = defaultTimeout
                urlSessionManager?.configuration.timeoutIntervalForResource = defaultTimeout
            }
            
            if let urlSessionManager = urlSessionManager {
                let dataTask = urlSessionManager.dataTask(with: request) { (data, response, error) in
                    if let httpResponse = (response as? HTTPURLResponse) {
                        let status = httpResponse.statusCode
                        if status < 400 && status >= 200 {
                            if let data = data {
                                callback(data, nil, response)
                            }else{
                                callback(nil, nil, response)
                            }
                        }else{
                           
                            callback(data, nil, response)
                        }
                    }else{
                        callback(nil, nil, response)
                    }
                }
                dataTask.resume()
            }
            else
            {
                callback(nil, nil, nil)
            }
            return nil
        }
    
    public func request (method: RequestMethod, path: String, headers: [String: String]?, format: ParameterFormat = ParameterFormat.PathParameter, queue: DispatchQueue = DispatchQueue.global(), timeout: Double? = nil, callback: @escaping APICallback){
        let _ : [String]? = self.requestRestAPI(method: method, path: path, params: nil, headers: headers, format: format, queue: queue, timeout: timeout) {
            (data, error, response) in
            callback(data, error, response)
        }
    }
    
    public func request (method: RequestMethod, path: String, params: [String]?, headers: [String: String]?, format: ParameterFormat = ParameterFormat.PathParameter, queue: DispatchQueue = DispatchQueue.global(), timeout: Double? = nil, callback: @escaping APICallback){
        let _ : [String]? = self.requestRestAPI(method: method, path: path, params: params, headers: headers, format: format, queue: queue, timeout: timeout) {
            (data, error, response) in
            callback(data, error, response)
        }
    }
    
    public func request (method: RequestMethod, path: String, params: [String: Any]?, headers: [String: String]?, format: ParameterFormat = ParameterFormat.PathParameter, queue: DispatchQueue = DispatchQueue.global(), timeout: Double? = nil, callback: @escaping APICallback){
        let _ : [String: Any]? = self.requestRestAPI(method: method, path: path, params: params, headers: headers, format: format, queue: queue, timeout: timeout) {
            (data, error, response) in
            callback(data, error, response)
        }
    }
    
    public func request (method: RequestMethod, path: String, params: [[String: Any]]?, headers: [String: String]?, format: ParameterFormat = ParameterFormat.PathParameter, queue: DispatchQueue = DispatchQueue.global(), timeout: Double? = nil, callback: @escaping APICallback){
        let _ : [[String: Any]]? = self.requestRestAPI(method: method, path: path, params: params, headers: headers, format: format, queue: queue, timeout: timeout) {
            (data, error, response) in
            callback(data, error, response)
        }
    }
    
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            let credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
            completionHandler(URLSession.AuthChallengeDisposition.useCredential, credential)
            if urlIgnoreSSLCertificate {
                if let trust = challenge.protectionSpace.serverTrust {
                    let credential = URLCredential(trust: trust)
                    completionHandler(.useCredential, credential)
                }else{
                    completionHandler(.performDefaultHandling, nil)
                }
            }else{
                completionHandler(.performDefaultHandling, nil)
            }
        }
        
        public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {}
        public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {}
}
