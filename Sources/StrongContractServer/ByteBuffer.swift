//
//  File.swift
//  
//
//  Created by Scott Lydon on 4/7/24.
//

import Foundation
import NIO

extension ByteBuffer {
    public var data: Data { .init(buffer: self) }
}
