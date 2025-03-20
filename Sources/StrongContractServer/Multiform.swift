//
//  File.swift
//  StrongContractServer
//
//  Created by Scott Lydon on 3/20/25.
//

import Vapor
import StrongContractClient

/// We conform `MultiFormData` to `Codable` so that it plays well with `Request`, even though we don't use that functionality.
struct MultiFormData<MetaData: Codable>: Codable, HasMultipleFormData where MetaData: HasFormat {
    var metaData: MetaData
    var data: Data
}

protocol HasMetaData {
    associatedtype MetaData: Codable, HasFormat
    var metaData: MetaData { get }
}

protocol HasFormat {
    var format: String { get }
}
protocol HasData {
    var data: Data { get }
}

typealias HasMultipleFormData = HasData & HasMetaData


extension StrongContractClient.Request {
    /// This method registers routes and exposes a callback for the request handler.
    /// - Parameters:
    ///   - app: The application's route builder where the route will be registered.
    ///   - verbose: Flag for enabling verbose logging.
    ///   - handler: Closure that processes the request and returns a response.
    func register<MetaData>(
        app: any RoutesBuilder,
        verbose: Bool = false,
        handler: @escaping @Sendable (Payload, Vapor.Request) async throws -> ResponseAdaptor
    ) where Payload == MultiFormData<MetaData>, MetaData: Codable & HasFormat {

        // Split the path by '/' to get individual components
        // Convert string path segments to PathComponent
        let pathComponents = path.split(separator: "/").map(String.init).map(PathComponent.init)

        if verbose {
            print(pathComponents)
        }

        switch method {
        case .get, .head:
            assertionFailure("Get/Head should not have a body.")
        case .post:
            app.post(pathComponents) {
                if verbose { print("We received: \($0)") }

                // The `$0` is a request
                // how do we get the payload, file from it?
                return try await handler(MultiFormData(metaData: $0.metaData(), data: $0.fileData()), $0).vaporResponse
            }
        case .put:
            app.put(pathComponents) {
                if verbose { print("We received: \($0)") }
                return try await handler(MultiFormData(metaData: $0.metaData(), data: $0.fileData()), $0).vaporResponse
            }
        case .delete:
            app.delete(pathComponents) {
                if verbose { print("We received: \($0)") }
                return try await handler(MultiFormData(metaData: $0.metaData(), data: $0.fileData()), $0).vaporResponse
            }
        case .patch:
            app.patch(pathComponents) {
                if verbose { print("We received: \($0)") }
                return try await handler(MultiFormData(metaData: $0.metaData(), data: $0.fileData()), $0).vaporResponse
            }
        }
    }
}

extension Vapor.Request {

    fileprivate func metaData<MetaData: Codable & HasFormat>() throws -> MetaData {
        if let rawBody = body.string, headers.contentType?.type == "multipart" {
            guard let metaDataRaw = rawBody.extractField(named: "metaData") else {
                throw Abort(.badRequest, reason: "Missing 'metaData' in form-data")
            }
            return try JSONDecoder().decode(MetaData.self, from: Data(metaDataRaw.utf8))
        }
        return try content.decode(MetaData.self)
    }

    fileprivate func fileData() throws -> Data {
        if let rawBody = body.string, headers.contentType?.type == "multipart" {
            guard let fileRaw = rawBody.extractField(named: "file") else {
                 throw Abort(.badRequest, reason: "Missing 'fileRaw' in form-data")
            }
            return Data(fileRaw.utf8)
        }
        return Data() // Default to empty Data if not found
    }
}

extension String {

    fileprivate func extractField(named key: String) -> String? {
        components(separatedBy: "--") // Split by boundary markers
            .first { $0.contains("Content-Disposition: form-data; name=\"\(key)\"") }?
            .components(separatedBy: "\n\n") // Split headers from content
            .dropFirst() // Remove headers
            .joined(separator: "\n") // Keep original line structure without adding extra gaps
            .trimmingCharacters(in: .whitespacesAndNewlines) // Clean up spaces
    }

    fileprivate func extractField2(named key: String) -> String? {
        let pattern = "--[^\\n]+\\nContent-Disposition: form-data; name=\"\(key)\"(?:;\\s*filename=\"[^\"]+\")?\\n\\n(.*?)(?:\\n--|--)"
        let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
        let nsString = self as NSString
        let match = regex?.firstMatch(in: self, options: [], range: NSRange(location: 0, length: nsString.length))

        if let range = match?.range(at: 1) {
            return nsString.substring(with: range)
        }
        return nil
    }

}
