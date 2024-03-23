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

/// magic number for resolution of hydrogen files
let hydrogenResolution: Int = 48

/// number of beats per quarter note in midi file
var midiResolution: Int = 0

/// number of beats per quarter in midi file / number of beats per quater in hydrogen
var resolutionRatio: Double = 1

/// Number of quarter beats in measure
let beatsInMeasure = 4

/// Lenght of one measure
let measureLength = beatsInMeasure * hydrogenResolution // Typically 192




public class Convertor: ObservableObject {

    var midiFileURL: URL?

    var hydrogenSong: XML?

    /// Array of rhytm patterns
    var patternList = [Pattern]()

    /// A sequence of patterns that makes song
    var patternSequence = [String]()

    var notes = [Note]()

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

        var patternNumber = 1
//        var lastMeasure: Int = 0
        var lastPositionInBeats: Double = 0
        var lastMeasureNumber = 0

        notes = []
        patternList = []

        firstTrack.events.forEach { event in
            guard 
                let status = event.status,
                let type = status.type,
                let positionInBeats = event.positionInBeats
            else {
                return
            }

            if type == .noteOn {
//                if Int(lastPositionInBeats / 4) != Int(positionInBeats / 4) {
//                    let pattern = Pattern(name: "Pattern\(patternNumber)", size: 192, noteList: notes)
//                    patternList.append(pattern)
//                    patternNumber += 1
//                    notes = []
//                }

                tickCount += (positionInBeats - lastPositionInBeats) * Double(midiResolution)
                lastPositionInBeats = positionInBeats

//                let tickCountFromMeasure = tickCount - Double(measureStart) * Double(midiResolution)

                let position = Int(round(Double(tickCount) / resolutionRatio))
                
                if (position / 192) > lastMeasureNumber {
                    let pattern = Pattern(name: "Pattern\(patternNumber)", size: 192, noteList: notes)
                    patternList.append(pattern)
                    patternNumber += 1
                    notes = []
                }

                // The begin of current measure
                lastMeasureNumber = (position / measureLength)
                let notePosition = Int(round(Double(tickCount) / resolutionRatio)) - lastMeasureNumber * measureLength

                notes.append(
                    Note(
                        position: notePosition,
                        velocity: Double(event.data[2]) / 127.0,
                        instrument: Int(event.data[1] - 36)
                    )
                )
            } else if type == .noteOff {
                tickCount += (positionInBeats - lastPositionInBeats) * Double(midiResolution)
                lastPositionInBeats = positionInBeats
            }
        }

        let quarterNotesCount  = ceil(tickCount / Double(midiResolution))
        let length = quarterNotesCount * Double(hydrogenResolution)
       
        // let pattern = Pattern(name: "Pattern1", size: Int(length), noteList: notes)
        let pattern = Pattern(name: "Pattern\(patternNumber)", size: 192, noteList: notes)
        patternList.append(pattern)

        patternSequence = patternList.map { $0.name }
    }

    public func saveHydrogenSong(url: URL) throws {
        // let modifiedUrl = url.deletingPathExtension().appendingPathExtension("h2song")
//        let documentUrl = url.deletingPathExtension().appendingPathExtension("h2song")
        try? FileManager.default.removeItem(at: url)

        hydrogenSong = XML(string: song)
        savePatternList()
        savePatternSequence()

        let contents = hydrogenSong?.toXMLString()
        try contents?.write(to: url, atomically: true, encoding: .utf8)
    }


    private func savePatternList() {
        guard let patternListTag = try? hydrogenSong?.patternList.getXML() else { return }
        for pattern in patternList {
            patternListTag.addChild(patternXML(pattern))
        }
    }

    private func patternXML(_ pattern: Pattern) -> XML {
        let nameTag = XML(name: "name", value: pattern.name)
        let infoTag = XML(name: "info")
        let categoryTag = XML(name: "category", value: "unknown")
        let sizeTag = XML(name: "size", value: pattern.size)
        let denominatorTag = XML(name: "denominator", value: "4")
        let noteListTag = XML(name: "noteList")
        for note in pattern.noteList {
            let positionTag = XML(name: "position", value: note.position)
            let leadlagTag = XML(name: "leadlag", value: 0)
            let velocityTag = XML(name: "velocity", value: note.velocity)
            let panTag = XML(name: "pan", value: 0)
            let pitchTag = XML(name: "pitch", value: 0)
            let keyTag = XML(name: "key", value: "C0")
            let lengthTag = XML(name: "length", value: "-1")
            let instrumentTag = XML(name: "instrument", value: note.instrument)
            let noteOffTag = XML(name: "note_off", value: false)
            let probabilityTag = XML(name: "probability", value: 1)

            let noteTag = XML(name: "note")
                .addChildren([positionTag, leadlagTag, velocityTag, panTag, pitchTag, keyTag, lengthTag, instrumentTag, noteOffTag, probabilityTag])

            noteListTag.addChild(noteTag)
        }

        let patternTag = XML(name: "pattern")
            .addChildren([nameTag, infoTag, categoryTag, sizeTag, denominatorTag, noteListTag])

        return patternTag
    }

    private func savePatternSequence() {
        guard let patternSequenceTag = try? hydrogenSong?.patternSequence.getXML() else { return }

        for item in patternSequence {
            let patternId = XML(name: "patternID", value: item)
            let groupTag = XML(name: "group").addChild(patternId)
            patternSequenceTag.addChild(groupTag)
        }
    }
}
