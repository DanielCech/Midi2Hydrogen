import AudioKit
import AudioKitEX
import AudioKitUI
import SwiftUI

public struct MIDITrackDemo: View {
    @StateObject var viewModel = MIDITrackViewModel()
    @State var fileURL: URL? = Bundle.module.url(forResource: "MIDI Files/Walkabout", withExtension: "mid")
    @State var isPlaying = false
    @State private var isImporting: Bool = false

    public init() {

    }

    public var body: some View {
        VStack(spacing: 80) {
            HStack(spacing: 20) {
                Button("Open MIDI File...") {
                    isImporting = true
                }
                .padding()
                .foregroundColor(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color.white, lineWidth: 2)
                )
                .fileImporter(isPresented: $isImporting,
                              allowedContentTypes: [.png, .jpeg, .tiff],
                              onCompletion: { result in

                    switch result {
                    case .success(let url):
                        print("success")
                        // url contains the URL of the chosen file.
                    case .failure(let error):
                        print(error)
                    }
                })


                Button("Convert to Hydrogen Song") {

                }
                .padding()
                .foregroundColor(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color.white, lineWidth: 2)
                )
            }

            Spacer()

            GeometryReader { geometry in
                if let fileURL = fileURL {
                    ForEach(
                        MIDIFile(url: fileURL).tracks.indices, id: \.self
                    ) { number in
                        MIDITrackView(fileURL: $fileURL,
                                      trackNumber: number,
                                      trackWidth: geometry.size.width,
                                      trackHeight: 200.0)
                        .background(Color.primary)
                        .cornerRadius(10.0)
                    }
                }
            }

            Spacer()
        }
        .padding()
        .background(
            Image("Background")
                .resizable(resizingMode: .stretch)
        )
        .navigationBarTitle(Text("Midi2Hydrogen"))
        .onTapGesture {
            isPlaying.toggle()
        }
        .onChange(of: isPlaying, perform: { newValue in
            if newValue == true {
                viewModel.play()
            } else {
                viewModel.stop()
            }
        })
        .onAppear(perform: {
            viewModel.startEngine()
            if let fileURL = Bundle.module.url(forResource: "MIDI Files/Walkabout", withExtension: "mid") {
                viewModel.loadSequencerFile(fileURL: fileURL)
            }
        })
        .onDisappear(perform: {
            viewModel.stop()
            viewModel.stopEngine()
        })
        .environmentObject(viewModel)
}
}
