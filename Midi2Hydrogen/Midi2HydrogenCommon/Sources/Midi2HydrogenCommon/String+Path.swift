//
//  String+Path.swift
//  
//
//  Created by Daniel Cech on 26.03.2024.
//

import Foundation

extension String {
    var withoutExtension: String {
        NSString(string: self).deletingPathExtension
    }
}
