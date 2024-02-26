import Files
import Foundation
import Moderator
import ScriptToolkit
import SwiftShell
import CoreMIDI

let moderator = Moderator(description: "Midi2Hydrogen - Convert MIDI files to Hydrogen songs")

let inputFileArgument = Argument<String?>
    .optionWithValue("input", name: "Input file", description: "Path to MIDI file")
let inputFile = moderator.add(inputFileArgument)

let outputFileArgument = Argument<String?>
    .optionWithValue("output", name: "Output file", description: "Path to result Hydrogen song")
let outputFile = moderator.add(outputFileArgument)

do {
    try moderator.parse()

    guard let inputFileName = inputFile.value else {
        print(moderator.usagetext)
        exit(0)
    }

    var outputFileName: String
    if let output = outputFile.value {
        outputFileName = output
    } else {
        outputFileName = inputFileName + ".h2song"
    }

    print("⌚️ Processing")

    try convertMIDItoHydrogen(input: inputFileName, output: outputFileName)

    print("✅ Done")
}
catch {
    print(error.localizedDescription)

    exit(Int32(error._code))
}
