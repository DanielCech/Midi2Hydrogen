//
//  File.swift
//  
//
//  Created by Daniel Cech on 06.04.2024.
//

import Foundation

final class ContentViewModel: ObservableObject {
    let convertor = Convertor()

    @Published var midiInstruments = [Int]()

    func openFile(url: URL) {
        convertor.openFile(url: url)
        midiInstruments = Array(convertor.midiInstruments)
//            .map { String($0) }
            .sorted()
    }

    func saveHydrogenSong(url: URL) throws {
        try convertor.saveHydrogenSong(url: url)
    }

}
