import AudioKit
import AudioKitEX
import AudioKitUI
import AVFoundation
import SwiftUI

// Helper functions
class Midi2Hydrogen {
    static var sourceBuffer: AVAudioPCMBuffer {
        let url = Bundle.module.resourceURL?.appendingPathComponent("Samples/beat.aiff")
        let file = try! AVAudioFile(forReading: url!)
        return try! AVAudioPCMBuffer(file: file)!
    }
}
