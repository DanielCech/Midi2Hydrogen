import AudioKit
import AudioKitEX
import AudioKitUI
import AVFoundation
import SoundpipeAudioKit
import SwiftUI

class ModalResonanceFilterConductor: ObservableObject, ProcessesPlayerInput {
    let engine = AudioEngine()
    let player = AudioPlayer()
    let filter: ModalResonanceFilter
    let dryWetMixer: DryWetMixer
    let buffer: AVAudioPCMBuffer

    init() {
        buffer = Midi2Hydrogen.sourceBuffer
        player.buffer = buffer
        player.isLooping = true

        filter = ModalResonanceFilter(player)
        dryWetMixer = DryWetMixer(player, filter)
        engine.output = dryWetMixer
    }
}

struct ModalResonanceFilterView: View {
    @StateObject var conductor = ModalResonanceFilterConductor()

    var body: some View {
        VStack {
            PlayerControls(conductor: conductor)
            HStack {
                ForEach(conductor.filter.parameters) {
                    ParameterRow(param: $0)
                }
                ParameterRow(param: conductor.dryWetMixer.parameters[0])
            }
            DryWetMixView(dry: conductor.player,
                          wet: conductor.filter,
                          mix: conductor.dryWetMixer)
        }
        .padding()
        .midi2HydrogenNavBarTitle("Modal Resonance Filter")
        .onAppear {
            conductor.start()
        }
        .onDisappear {
            conductor.stop()
        }
    }
}