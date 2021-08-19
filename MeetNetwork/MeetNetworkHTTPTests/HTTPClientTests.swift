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
        // Using this, a new instance of ShoppingCart will be created
        // before each test is run.
        client = HTTPClient.shared
    }


    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    // MARK: - URL REQUEST METHODS
    
    func testCreateURLRequestInvalid() {
        // Given
        // When
        let request = client.createURLRequest(url: "test test", method: HTTPMethod.get)

        // Then
        XCTAssertNil(request)
    }
    
    /// Test create GET request
    func testCreateURLRequestGET() {
        // Given
        // When
        let request = client.createURLRequest(url: "https://test.com", method: HTTPMethod.get)

        // Then
        XCTAssertEqual(request!.httpMethod, "GET")
    }
    
    /// Test create POST request
    func testCreateURLRequestPOST() {
        // Given
        // When
        let request = client.createURLRequest(url: "https://test.com", method: HTTPMethod.post)

        // Then
        XCTAssertEqual(request!.httpMethod, "POST")
    }
    
    /// Test create PUT request
    func testCreateURLRequestPUT() {
        // Given
        // When
        let request = client.createURLRequest(url: "https://test.com", method: HTTPMethod.put)

        // Then
        XCTAssertEqual(request!.httpMethod, "PUT")
    }
    
    /// Test create DELETE request
    func testCreateURLRequestDELETE() {
        // Given
        // When
        let request = client.createURLRequest(url: "https://test.com", method: HTTPMethod.delete)

        // Then
        XCTAssertEqual(request!.httpMethod, "DELETE")
    }
    
    // MARK: - HEADER
    
    // Tests add header to request
    func testAddRequestHeaders() {
        // Given
        var request = client.createURLRequest(url: "https://test.com", method: HTTPMethod.get)
        let headers = ["TEST1-Accept-Charset" : "utf-8", "TEST2-Content-Type" : "application/json"]
        
        // When
        client.addRequestHeaders(request: &request!, headers: headers)

        // Then
        XCTAssertEqual(request!.value(forHTTPHeaderField:"TEST1-Accept-Charset"), "utf-8")
        XCTAssertEqual(request!.value(forHTTPHeaderField:"TEST2-Content-Type"), "application/json")
        
        XCTAssertEqual(request!.allHTTPHeaderFields?.count, 2)
    }

    // MARK: - PARAMS
    
    func testAddGetParameterAssertURL() {
        // Given
        var request = client.createURLRequest(url: "https://test.com", method: HTTPMethod.get)
        let params = ["test1" : "value1"]
        
        // When
        client.addGetParameters(request: &request!, parameters: params)

        // Then
        XCTAssertEqual(request?.url?.absoluteString, "https://test.com?test1=value1")
    }
    
    func testAddGetParameterSpaceAssertURL() {
        // Given
        var request = client.createURLRequest(url: "https://test.com", method: HTTPMethod.get)
        let params = ["test1" : "value 1"]
        
        // When
        client.addGetParameters(request: &request!, parameters: params)

        // Then
        XCTAssertEqual(request?.url?.absoluteString, "https://test.com?test1=value%201")
    }
    
    func testAddGetParameters() {
        // Given
        var request = client.createURLRequest(url: "https://test.com", method: HTTPMethod.get)
        let params = ["test1" : "value 1", "test2" : "value2", "test3" : "value3"]
        
        // When
        client.addGetParameters(request: &request!, parameters: params)

        // Then
        let compareUrl = URLComponents(url: request!.url!, resolvingAgainstBaseURL: true)
        let queryItems = compareUrl!.queryItems
        
        XCTAssertEqual(queryItems!.count, 3)
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
