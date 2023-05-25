import UIKit
import Combine

class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func stopLoading() { }
    
    override func startLoading() {
         guard let handler = MockURLProtocol.requestHandler else {
            return
        }
        
        do {
            let (response, data)  = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch  {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
}

func setMockProtocol() {
    MockURLProtocol.requestHandler = { request in
        let exampleData =
        """
        {
        "base": "USD"
        }
        """
            .data(using: .utf8)!
        let response = HTTPURLResponse.init(url: request.url!, statusCode: 200, httpVersion: "2.0", headerFields: nil)!
        return (response, exampleData)
    }
}

// Example of decodable object
struct Object: Codable {
    let base: String
}

// Mock URL
let url = URL(string: "some_url")!

// Configure session
let sessionConfiguration = URLSessionConfiguration.ephemeral
sessionConfiguration.protocolClasses = [MockURLProtocol.self]
let session = URLSession(configuration: sessionConfiguration)
setMockProtocol()

// Make request
session.dataTask(with: url) { data, response, error in
    
    guard let data = data else { return }
    do {
        let response = try JSONDecoder().decode(Object.self, from: data)
        print(response)
    } catch {
        print(error)
    }
}.resume()
