//
//  NewsAPI.swift
//  SignpostDemo
//
//  Created by Ben Scheirman on 7/27/18.
//  Copyright © 2018 NSScreencast. All rights reserved.
//

import Foundation
import os.signpost

class NewsAPI {
    
    enum Result<T> {
        case success(T)
        case failed(Error)
    }
    
    typealias CompletionBlock<T> = (Result<T>) -> Void where T : Decodable
    
    private enum Endpoint {
        case topStories
        case item(Int)
        
        var baseURL: URL {
            return URL(string: "https://hacker-news.firebaseio.com/v0")!
        }
        
        var url: URL {
            switch self {
            case .topStories:
                return baseURL.appendingPathComponent("topstories.json")
            case .item(let id):
                return baseURL.appendingPathComponent("item/\(id).json")
            }
        }
    }
    
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    @discardableResult
    func loadTopStories(completion: @escaping CompletionBlock<[Int]>) -> URLSessionDataTask {
        return fetch(.topStories) { result in
            self.parse(result) { r in
                self.dispatchResult(r, completion: completion)
            }
        }
    }
    
    @discardableResult
    func loadStory(id: Int, completion: @escaping CompletionBlock<Story>) -> URLSessionDataTask {
        var task: URLSessionDataTask?
        task = fetch(.item(id)) { [weak task] result in
            if task?.state == .canceling {
                self.dispatchResult(.failed(Errors.cancelled), completion: completion)
            } else {
                self.parse(result) { r in
                    self.dispatchResult(r, completion: completion)
                }
            }
        }
        return task!
    }
    
    private func dispatchResult<T>(_ result: Result<T>, completion: @escaping CompletionBlock<T>) {
        DispatchQueue.main.async {
            completion(result)
        }
    }
    
    private func fetch(_ endpoint: Endpoint, completion: @escaping CompletionBlock<Data> ) -> URLSessionDataTask {
        let task = session.dataTask(with: endpoint.url) { data, response, error in
            if let error = error {
                completion(.failed(error))
            } else {
                guard let http = response as? HTTPURLResponse else {
                    completion(.failed(Errors.networkFault))
                    return
                }
                guard let data = data else {
                    completion(.failed(Errors.emptyResponse))
                    return
                }
                switch http.statusCode {
                case 200:
                    completion(.success(data))
                default:
                    completion(.failed(Errors.requestFailed))
                }
            }
        }
        task.resume()
        return task
    }
    
    private func parse<T : Decodable>(_ result: Result<Data>, _ completion: @escaping CompletionBlock<T>) {
        switch result {
        case .success(let data):
            do {
                os_signpost(.begin, log: SignpostLog.json, name: "Decode JSON")
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .secondsSince1970
                let object = try decoder.decode(T.self, from: data)
                os_signpost(.end, log: SignpostLog.json, name: "Decode JSON", "%s", String(describing: object))
                completion(.success(object))
            } catch {
                completion(.failed(error))
            }
            
        case .failed(let error):
            completion(.failed(error))
        }
    }
    
    public struct Errors {
        static var domain = "com.ficklebits.newsapi"
        
        static var networkFault: Error {
            return NSError(domain: domain, code: 1, userInfo: nil)
        }
        
        static var emptyResponse: Error {
            return NSError(domain: domain, code: 2, userInfo: nil)
        }
        
        static var requestFailed: Error {
            return NSError(domain: domain, code: 3, userInfo: nil)
        }
        
        static var cancelled: Error {
            return NSError(domain: domain, code: 4, userInfo: nil)
        }
    }
}
