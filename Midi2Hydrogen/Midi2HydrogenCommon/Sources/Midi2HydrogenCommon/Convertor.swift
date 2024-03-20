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

struct Note {
    let position: Int
    let velocity: Double
    let instrument: Int
}


public class Convertor: ObservableObject {

    var hydrogenSong: XML?

    /// magic number for resolution of hydrogen files
    let hydrogenResolution: Int = 48

    /// number of beats per quarter note in midi file
    var midiResolution: Int = 0

    /// number of beats per quarter in midi file / number of beats per quater in hydrogen
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
        
        var tickCount: Double = 0
        var notes = [Note]()

        firstTrack.events.forEach { event in
            guard 
                let status = event.status,
                let type = status.type,
                let positionInBeats = event.positionInBeats
            else {
                return
            }

            if type == .noteOn {
                tickCount += positionInBeats * Double(midiResolution)
                notes.append(
                    Note(
                        position: Int(round(Double(tickCount) / resolutionRatio)),
                        velocity: Double(event.data[2]) / 127.0,
                        instrument: Int(event.data[1] - 36)
                    )
                )
            } else if type == .noteOff {
                tickCount += positionInBeats * Double(midiResolution)
            }
        }

    }

    public func openSong() {
        hydrogenSong = XML(string: song)
        print(String(describing: hydrogenSong))
    }
}
