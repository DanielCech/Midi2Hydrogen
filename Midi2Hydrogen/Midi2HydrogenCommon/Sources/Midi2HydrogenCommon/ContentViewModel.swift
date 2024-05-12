//
//  ContentViewModel.swift
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

public class ContentViewModel: ObservableObject {

    @Published var tracks = [String]()

    // MARK: - Instruments

    @Published var midiInstruments = [Int]()

    /// Instrument assignment
    @Published var instrumentMapping = [Int: String]()

    @Published var drumkit: String = "GMRockKit"
    @Published var drumkitPath: String = ""

    /// Available instruments in the drumkit
    @Published var drumkitInstruments = [String]()

    var instrumentMappingKeys: [Int] {
        instrumentMapping.keys
            .sorted()
    }

    // MARK: - Parameters

    /// magic number for resolution of hydrogen files
    let hydrogenResolution: Int = 48

    /// number of beats per quarter note in midi file
    var midiResolution: Int = 0

    /// number of beats per quarter in midi file / number of beats per quater in hydrogen
    var resolutionRatio: Double = 1

    /// Number of quarter beats in measure
    let beatsInMeasure = 4

    /// Lenght of one measure
    lazy var measureLength = beatsInMeasure * hydrogenResolution // Typically 192

    // MARK: - Files

    /// Input file
    var midiFile: MIDIFile?

    /// Input file URL
    var midiFileURL: URL?

    /// Output file XML structure
    var hydrogenSong: XML?

    var instrumentList: XML?

    // MARK: - Patterns

    /// Array of rhytm patterns
    var patternList = [Pattern]()

    /// A sequence of patterns that makes song
    var patternSequence = [String]()

    /// The counter of patterns in song
    var patternNumber = 1

    /// Notes in the current pattern
    var notes = [Note]()

    init() {
        openHydrogenSongTemplate()
        processDrumkitInstruments(instrumentList: XML(string: gmRockKitInstrumentListXML))
    }

    /// Initial preprocessing of file
    public func openFile(url: URL) {
        midiFileURL = url
        midiFile = MIDIFile(url: url)

        guard let midiFile else { return }

        midiResolution = Int(midiFile.timeDivision)
        resolutionRatio = Double(midiResolution) / Double(hydrogenResolution)

        tracks = (0 ..< midiFile.tracks.count).map { String($0) }
    }

    /// Preprocess selected track
    public func preprocessSelectedTrack(track: Int) {
        guard let track = midiFile?.tracks[safe: track] else {
            fatalError("MIDI file does not contain tracks")
        }

        instrumentMapping = [:]

        track.events.forEach { event in
            guard
                let status = event.status,
                let type = status.type
            else {
                return
            }

            if type == .noteOn {
                let midiKey = Int(event.data[1])

                if let drumkitInstrument = drumkitInstruments[safe: midiKey - 36] {
                    instrumentMapping[midiKey] = drumkitInstrument
                }
            }
        }

        midiInstruments = Array(instrumentMapping.keys).sorted()
    }

    /// Preprocess selected track
    public func convert(track: Int) {
        guard let track = midiFile?.tracks[safe: track] else {
            fatalError("MIDI file does not contain tracks")
        }

        var tickCount: Double = 0
        var lastPositionInBeats: Double = 0
        var lastMeasureNumber = 0

        patternList = []
        patternSequence = []
        patternNumber = 1
        notes = []

        track.events.forEach { event in
            guard
                let status = event.status,
                let type = status.type,
                let positionInBeats = event.positionInBeats
            else {
                return
            }

            if type == .noteOn {
                tickCount += (positionInBeats - lastPositionInBeats) * Double(midiResolution)
                lastPositionInBeats = positionInBeats

                let position = Int(round(Double(tickCount) / resolutionRatio))

                if (position / 192) > lastMeasureNumber {
                    addPattern()
                }

                // The begin of current measure
                lastMeasureNumber = (position / measureLength)
                let notePosition = Int(round(Double(tickCount) / resolutionRatio)) - lastMeasureNumber * measureLength

                let midiInstrument = Int(event.data[1])
                let mappedInstrument: Int

                if
                    let instrumentString = instrumentMapping[midiInstrument],
                    let instrumentInt = drumkitInstruments.firstIndex(of: instrumentString)
                {
                    mappedInstrument = instrumentInt
                } else {
                    mappedInstrument = 35 // Some fallback value
                }

                notes.append(
                    Note(
                        position: notePosition,
                        velocity: Double(event.data[2]) / 127.0,
                        instrument: mappedInstrument
                    )
                )
            } else if type == .noteOff {
                tickCount += (positionInBeats - lastPositionInBeats) * Double(midiResolution)
                lastPositionInBeats = positionInBeats
            }
        }

        addPattern()
    }

    private func addPattern() {
        let pattern = Pattern(name: "Pattern\(patternNumber)", size: 192, noteList: notes)

        for knownPattern in patternList {
            if knownPattern == pattern {
                patternSequence.append(knownPattern.name)
                notes = []
                return
            }
        }

        patternList.append(pattern)
        patternSequence.append(pattern.name)
        patternNumber += 1
        notes = []
    }

    func openHydrogenSongTemplate() {
        hydrogenSong = XML(string: gmRockKitSongXML)
    }

    public func saveHydrogenSong(url: URL) throws {
        try? FileManager.default.removeItem(at: url)

        openHydrogenSongTemplate()
        savePatternList()
        savePatternSequence()
        safeInstrumentList()

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

    private func safeInstrumentList() {
        if let instrumentList {
            hydrogenSong?.addChild(instrumentList)
        } else {
            hydrogenSong?.addChild(XML(string: gmRockKitInstrumentListXML))
        }
    }

    private func processDrumkitInstruments(instrumentList: XML) {
        if let value = try? instrumentList.xmlChildren.first!.drumkitPath.getXML().stringValue {
            drumkitPath = value
        }

        self.instrumentList = instrumentList
        drumkitInstruments = []

        for instrument in instrumentList.xmlChildren {
            if let instrumentName = instrument.name.string {
                drumkitInstruments.append(instrumentName)
            }
        }

        if let firstInstrument = instrumentList.xmlChildren.first {
            if let value = try? firstInstrument.drumkit.getXML().stringValue {
                drumkit = value
            } else {
                drumkit = ""
            }

            if let value = try? firstInstrument.drumkitPath.getXML().stringValue {
                drumkitPath = value
            } else {
                drumkitPath = ""
            }
        }
    }
}

// MARK: - Drumkits from song

extension ContentViewModel {
    func loadDrumkit(url: URL) {
        guard let drumkitXML = XML(url: url) else {
            return
        }

        guard let instrumentList = try? drumkitXML.instrumentList.getXML() else { return }
        processDrumkitInstruments(instrumentList: instrumentList)
    }
}

// MARK: - Import and Export mapping

extension ContentViewModel {

    func loadMapping(url: URL) throws {
        let jsonData = try Data(contentsOf: url)
        guard let dict = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: String] else { return }

        var convertedInstrumentMapping = [Int: String]()
        dict.forEach { (key: String, value: String) in
            if let intKey = Int(key) {
                convertedInstrumentMapping[intKey] = value
            }
        }

        instrumentMapping = convertedInstrumentMapping
    }

    func saveMapping(url: URL) throws {
        var convertedInstrumentMapping = [String: String]()
        instrumentMapping.forEach { (key: Int, value: String) in
            convertedInstrumentMapping[String(key)] = value
        }

        let jsonData = try JSONSerialization.data(withJSONObject: convertedInstrumentMapping, options: .prettyPrinted)
        try jsonData.write(to: url)
    }
}
