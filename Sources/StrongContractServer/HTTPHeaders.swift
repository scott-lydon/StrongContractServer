//
//  File.swift
//  
//
//  Created by Scott Lydon on 4/18/24.
//

import NIOHTTP1

extension HTTPHeaders {
    public static var defaultJson: HTTPHeaders {
        var headers = HTTPHeaders()
        headers.add(name: "Content-Type", value: "application/json")
        return headers
    }
}
