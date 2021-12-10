//
//  MeetNetworkHTTPClientTests.swift
//  MeetNetworkHTTPTests
//
//  Created by Manel MeetingLawyers on 16/8/21.
//

import XCTest

@testable import MeetNetworkHTTP

class HTTPClientTests: XCTestCase {
    
    private var client: HTTPClient!

    override func setUp() {
        super.setUp()
        client = HTTPClient.shared
    }
    
    // MARK: - CONFIG
    
    func testTimeoutConfig() {
        let timeout = 42.0
        client.config(timeout: timeout)
        
        XCTAssertTrue(client.getSession().configuration.timeoutIntervalForRequest == timeout)
    }
    
    func testNoTimeoutConfig() {
        let timeout = 60.0
        
        XCTAssertTrue(client.getSession().configuration.timeoutIntervalForRequest == timeout)
    }
    
    // MARK: - URL REQUEST METHODS
    
    func testCreateURLRequestInvalid() {
        // Given
        // When
        let request = client.createURLRequest(url: "test test", method: HTTPMethod.get, headers: nil, parameters: nil)

        // Then
        XCTAssertNil(request)
    }
    
    /// Test create GET request
    func testCreateURLRequestGET() {
        // Given
        // When
        let request = client.createURLRequest(url: "https://test.com", method: HTTPMethod.get, headers: nil, parameters: nil)

        // Then
        XCTAssertEqual(request!.httpMethod, "GET")
    }
    
    /// Test create POST request
    func testCreateURLRequestPOST() {
        // Given
        // When
        let request = client.createURLRequest(url: "https://test.com", method: HTTPMethod.post, headers: nil, parameters: nil)

        // Then
        XCTAssertEqual(request!.httpMethod, "POST")
    }
    
    /// Test create PUT request
    func testCreateURLRequestPUT() {
        // Given
        // When
        let request = client.createURLRequest(url: "https://test.com", method: HTTPMethod.put, headers: nil, parameters: nil)

        // Then
        XCTAssertEqual(request!.httpMethod, "PUT")
    }
    
    /// Test create DELETE request
    func testCreateURLRequestDELETE() {
        // Given
        // When
        let request = client.createURLRequest(url: "https://test.com", method: HTTPMethod.delete, headers: nil, parameters: nil)

        // Then
        XCTAssertEqual(request!.httpMethod, "DELETE")
    }
    
    // MARK: - HEADER
    
    // Tests add header to request
    func testAddRequestHeaders() {
        // Given
        let headers = ["TEST1-Accept-Charset" : "utf-8", "TEST2-Content-Type" : "application/json"]
        
        // When
        let request = client.createURLRequest(url: "https://test.com", method: HTTPMethod.get, headers: headers, parameters: nil)
        var request2 = client.createURLRequest(url: "https://test.com", method: HTTPMethod.get, headers: nil, parameters: nil)
        client.addRequestHeaders(request: &request2!, headers: headers)
        
        // Then
        // Request 1
        XCTAssertEqual(request!.value(forHTTPHeaderField:"TEST1-Accept-Charset"), "utf-8")
        XCTAssertEqual(request!.value(forHTTPHeaderField:"TEST2-Content-Type"), "application/json")
        
        XCTAssertEqual(request!.allHTTPHeaderFields?.count, 2)
        // Request 2
        XCTAssertEqual(request2!.value(forHTTPHeaderField:"TEST1-Accept-Charset"), "utf-8")
        XCTAssertEqual(request2!.value(forHTTPHeaderField:"TEST2-Content-Type"), "application/json")
        
        XCTAssertEqual(request2!.allHTTPHeaderFields?.count, 2)
        
        XCTAssertEqual(request?.allHTTPHeaderFields, request2?.allHTTPHeaderFields)
    }

    // MARK: - PARAMS
    
    func testAddGetParametersAssertCountAndEquatable() {
        // Given
        struct Foo : Codable {
            var test1 : String
            var test2 : String
            var test3 : String
        }
        
        let params = ["test1" : "value 1", "test2" : "value2", "test3" : "value3"]
        let params2 = Foo(test1: "value 1", test2: "value2", test3: "value3")
        
        // When
        let request = client.createURLRequest(url: "https://test.com", method: HTTPMethod.get, headers: nil, parameters: params)
        var request2 = client.createURLRequest(url: "https://test.com", method: HTTPMethod.get, headers: nil, parameters: nil)
        client.addGetParameters(request: &request2!, parameters: params)
        let request3 = client.createURLRequest(url: "https://test.com", method: HTTPMethod.get, headers: nil, parameters: params2)

        // Then
        let compareUrl = URLComponents(url: request!.url!, resolvingAgainstBaseURL: true)
        let queryItems = compareUrl!.queryItems
        
        XCTAssertEqual(queryItems!.count, 3)
        
        let compareUrl2 = URLComponents(url: request2!.url!, resolvingAgainstBaseURL: true)
        let queryItems2 = compareUrl2!.queryItems
        
        XCTAssertEqual(queryItems2!.count, 3)
        
        let compareUrl3 = URLComponents(url: request3!.url!, resolvingAgainstBaseURL: true)
        let queryItems3 = compareUrl3!.queryItems
        
        XCTAssertEqual(queryItems3!.count, 3)
    }
    
    func testAddGetParametersAssertURLGeneration() {
        // Given
        struct Foo : Codable {
            var test1 : String
        }
        
        let params = ["test1" : "value1"]
        
        let params2 = Foo(test1: "value1")
        
        // When
        let request = client.createURLRequest(url: "https://test.com", method: HTTPMethod.get, headers: nil, parameters: params)
        
        let request2 = client.createURLRequest(url: "https://test.com", method: HTTPMethod.get, headers: nil, parameters: params2)
        
        // Then
        XCTAssertEqual(request?.url?.absoluteString, "https://test.com?test1=value1")
        XCTAssertEqual(request2?.url?.absoluteString, "https://test.com?test1=value1")
    }
    
    func testAddGetParametersSpaceAssertURLGeneration() {
        // Given
        struct Foo : Codable {
            var test1 : String
        }
        
        let params = ["test1" : "value 1"]
        let params2 = Foo(test1: "value 1")
        
        // When
        let request = client.createURLRequest(url: "https://test.com", method: HTTPMethod.get, headers: nil, parameters: params)
        let request2 = client.createURLRequest(url: "https://test.com", method: HTTPMethod.get, headers: nil, parameters: params2)
        
        // Then
        XCTAssertEqual(request?.url?.absoluteString, "https://test.com?test1=value%201")
        XCTAssertEqual(request2?.url?.absoluteString, "https://test.com?test1=value%201")
    }
    
    // MARK: - Handlers
    
    func testCompletionHandlerIsInMainThread() {
        // Given
        let wrapper = Wrapper(test: "test")
        let expectation = XCTestExpectation(description: "call success handler in the main thread")
        
        //When
        DispatchQueue.global().async {
            let result: HTTPResult<Wrapper, Wrapper> = .success(wrapper)
            self.client.callCompletionHandlerInMainThread(result: result) { Result in
                // Then
                XCTAssertTrue(Thread.isMainThread)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
}

private struct Wrapper: Decodable {
    let test: String
}
