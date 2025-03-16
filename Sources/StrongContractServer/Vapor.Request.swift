//
//  File.swift
//  
//
//  Created by Scott Lydon on 4/7/24.
//

import EncryptDecryptKey
import Vapor
import Callable
import StrongContractClient

extension Vapor.Request {
    
    func decryptedData() throws -> Data {
        guard let encryptedData = body.data?.data else {
            throw Abort(.badRequest, reason: "body data not found")
        }
        return try encryptedData.decrypt()
    }

    func decodedObject<T: Decodable>(using decoder: JSONDecoder = .init()) throws -> T {
        guard let data = body.data?.data else { throw GenericError(text: "Body data was nil") }
        return try data.decodedObject(using: decoder)
    }
}
