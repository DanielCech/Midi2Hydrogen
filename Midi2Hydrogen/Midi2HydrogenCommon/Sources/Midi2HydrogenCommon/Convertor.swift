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

    var midiFileURL: URL?

    var hydrogenSong: XML?

    /// magic number for resolution of hydrogen files
    let hydrogenResolution: Int = 48

    /// number of beats per quarter note in midi file
    var midiResolution: Int = 0

    /// number of beats per quarter in midi file / number of beats per quater in hydrogen
    var resolutionRatio: Double = 1

    var notes = [Note]()

    public init() {

    }

    public func openFile(url: URL) {
        midiFileURL = url

        let midiFile = MIDIFile(url: url)
        print(String(describing: midiFile))

        midiResolution = Int(midiFile.timeDivision)
        resolutionRatio = Double(midiResolution) / Double(hydrogenResolution)

        guard let firstTrack = midiFile.tracks.first else {
            fatalError("MIDI file does not contain tracks")
        }
        
        var tickCount: Double = 0

        notes = []

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

    public func saveHydrogenSong() throws {
        guard
            let midiFileURL
        else {
            return
        }


        let hydrogenSongURL = midiFileURL.appendingPathExtension("h2song")
        try? FileManager.default.removeItem(at: hydrogenSongURL)

        hydrogenSong = XML(string: song)

        let contents = hydrogenSong?.toXMLString()
        print(contents)
        // try contents?.write(to: hydrogenSongURL, atomically: true, encoding: .utf8)
    }
}
