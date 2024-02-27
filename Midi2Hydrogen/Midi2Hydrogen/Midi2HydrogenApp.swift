// Copyright AudioKit. All Rights Reserved.

import AudioKit
import AVFoundation
import Midi2HydrogenCommon
import SwiftUI

@main
struct Midi2HydrogenApp: App {
    init() {
        #if os(iOS)
            do {
                Settings.bufferLength = .short
                try AVAudioSession.sharedInstance().setPreferredIOBufferDuration(Settings.bufferLength.duration)
                try AVAudioSession.sharedInstance().setCategory(.playAndRecord,
                                                                options: [.defaultToSpeaker, .mixWithOthers, .allowBluetoothA2DP])
                try AVAudioSession.sharedInstance().setActive(true)
            } catch let err {
                print(err)
            }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            MIDITrackDemo()
        }
    }
}
