//
//  Convertor.swift
//
//
//  Created by Daniel Cech on 28.02.2024.
//

import Foundation
import SwiftyXML
import AudioKit
import AudioKitEX
import AudioKitUI
import SwiftUI

public class Convertor: ObservableObject {

    var hydrogenSong: XML?

    let hydrogenResolution: Int = 48
    var midiResolution: Int = 0
    var resolutionRatio: Double = 1

    public init() {

    }

    public func openFile(url: URL) {
        let midiFile = MIDIFile(url: url)
        print(String(describing: midiFile))

        midiResolution = Int(midiFile.timeDivision)
        resolutionRatio = Double(midiResolution) / Double(hydrogenResolution)

        guard let firstTrack = midiFile.tracks.first else {
            fatalError("MIDI file does not contain tracks")
        }
        
        var tickCount = 0

        firstTrack.events.forEach { event in

        }

    }

    public func openSong() {
        hydrogenSong = XML(string: song)
        print(String(describing: hydrogenSong))
    }
}
