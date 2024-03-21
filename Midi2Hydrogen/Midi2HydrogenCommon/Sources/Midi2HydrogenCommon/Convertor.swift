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

    public func saveHydrogenSong(url: URL) throws {
        // let modifiedUrl = url.deletingPathExtension().appendingPathExtension("h2song")

        try? FileManager.default.removeItem(at: url)

        hydrogenSong = XML(string: song)
        savePatternList()
        savePatternSequence()

        let contents = hydrogenSong?.toXMLString()
        try contents?.write(to: url, atomically: true, encoding: .utf8)
    }


    private func savePatternList() {
        guard let song = try? hydrogenSong?.song.getXML() else { return }
        let patternList = song.addChild(XML(named: "patternList"))
        patternList.addChild(XML(named: "pattern"))
    }

    private func savePatternSequence() {
        guard let song = try? hydrogenSong?.song.getXML() else { return }
        let patternSequence = song.addChild(XML(named: "patternSequence"))
        patternSequence.addChild(XML(named: "pattern"))
    }
}
