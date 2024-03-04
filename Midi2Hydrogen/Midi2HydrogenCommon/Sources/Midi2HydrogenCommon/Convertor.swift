//
//  Convertor.swift
//
//
//  Created by Daniel Cech on 28.02.2024.
//

import Foundation
import SwiftyXML

public class Convertor: ObservableObject {

    var hydrogenSong: XML?

    public init() {

    }

    public func openFile(url: URL) {
        // TODO
    }

    public func openSong() {
        hydrogenSong = XML(string: song)
        print(String(describing: hydrogenSong))
    }
}
