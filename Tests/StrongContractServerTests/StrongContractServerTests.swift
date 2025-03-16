import XCTest
@testable import StrongContractServer
@testable import StrongContractClient
import Vapor


struct MockResponse: Codable {
    var message: String
}

// A custom Encodable type that always fails during encoding
struct AlwaysFailingEncoder: Codable {
    func encode(to encoder: Encoder) throws {
        throw GenericError(text: "Always fails")
    }
}

// Example of a response type that uses AlwaysFailingEncoder
struct ErrorOnEncodeResponse: Codable {
    var message: String
    var failingPart: AlwaysFailingEncoder
}

extension Data {
    func decrypt() throws -> Data {
        return Data(self.reversed())
    }
}


// Custom error used in the extension, define it if not already defined
struct GenericError: Error, LocalizedError {
    var text: String
    var errorDescription: String? { return text }
}



final class StrongContractServerTests: XCTestCase {
    func testExample() throws {
        // XCTest Documentation
        // https://developer.apple.com/documentation/xctest

        // Defining Test Cases and Test Methods
        // https://developer.apple.com/documentation/xctest/defining_test_cases_and_test_methods
    }

    func testResponseAdaptorInitializationWithError() {
        // Setup
        let response = AlwaysFailingEncoder()
        // ErrorOnEncodeResponse(message: "This should fail", failingPart: AlwaysFailingEncoder())


        // Test
        XCTAssertThrowsError({
            _ = try StrongContractClient.Request<Empty, AlwaysFailingEncoder>.ResponseAdaptor(
                body: response
            )
        }, "The initializer should throw an error when encoding fails") { error in
            if let error = error as? GenericError {
                XCTAssertEqual(error.text, "Always fails", "The error message should indicate why the encoding failed")
            } else {
                XCTFail("Error thrown was not a GenericError as expected.")
            }
        }
    }


    func testInvalidPath() {
        // Setup
        var components = URLComponents()
        components.scheme = "https"
        components.host = "example.com"
        components.path = "noLeadingSlash"  // Invalid because it doesn't start with "/"

        // Test and verify
        XCTAssertThrowsError(try components.urlAndValidate()) { error in
            XCTAssertEqual(error as? URLValidationError, .invalidPath("Current path: noLeadingSlash"))
        }
    }


    func testResponseAdaptorInitializationSuccess() {
        // Setup
        let response = MockResponse(message: "Success")
        let encoder = JSONEncoder()

        // Test
        XCTAssertNoThrow({
            let adaptor = try StrongContractClient.Request<Empty, MockResponse>.ResponseAdaptor(
                status: .ok,
                body: response,
                using: encoder
            )
            XCTAssertEqual(adaptor.status, .ok)
            XCTAssertEqual(adaptor.version, .http1_1)
            XCTAssertEqual(adaptor.headers, .defaultJson)
            XCTAssertNotNil(adaptor.data)
        }, "Initialization should succeed without throwing an error")
    }

    func testVaporResponseGeneration() {
        // Setup
        let response = MockResponse(message: "Test")
        let adaptor = try! StrongContractClient.Request<Empty, MockResponse>.ResponseAdaptor(
            body: response,
            using: JSONEncoder()
        )

        // Test
        let vaporResponse = adaptor.vaporResponse

        // Verify
        XCTAssertEqual(vaporResponse.status, .ok)
        XCTAssertEqual(vaporResponse.version, .http1_1)
        XCTAssertEqual(vaporResponse.headers["Content-Length"].first, String(adaptor.data.readableBytes))
        XCTAssertNotNil(vaporResponse.body)
    }
}
