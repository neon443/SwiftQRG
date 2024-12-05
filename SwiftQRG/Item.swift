//
//  Item.swift
//  SwiftQRG
//
//  Created by Nihaal Sharma on 05/12/2024.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
