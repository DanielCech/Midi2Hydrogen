//
//  Pattern.swift
//  
//
//  Created by Daniel Cech on 21.03.2024.
//

import Foundation

struct Pattern: Equatable {
    let name: String
    let size: Int
    let noteList: [Note]

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.noteList == rhs.noteList
    }
}
