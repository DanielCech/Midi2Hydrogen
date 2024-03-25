import AudioKit
import AudioKitEX
import AudioKitUI
import SwiftUI
import UniformTypeIdentifiers

public struct ContentView: View {
    @StateObject var viewModel = MIDITrackViewModel()
    @StateObject var convertor = Convertor()
    @State var fileURL: URL? // = Bundle.module.url(forResource: "MIDI Files/Walkabout", withExtension: "mid")
    @State var isPlaying = false
    @State private var isImporting: Bool = false
    @State private var isExporting: Bool = false
    @State private var isFileOpen: Bool = false

    @State private var document = HydrogenSongFile()

    public init() {

    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 80) {
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
                              allowedContentTypes: [.midi],
                              onCompletion: { result in

                    switch result {
                    case .success(let url):
                        isFileOpen = true
                        fileURL = url
                        viewModel.loadSequencerFile(fileURL: url)
                        convertor.openFile(url: url)

                    case .failure(let error):
                        print(error)
                    }
                })


                Button("Convert to Hydrogen Song") {
                    isExporting = true
                }
                .padding()
                .foregroundColor(isFileOpen ? .white : .gray)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(isFileOpen ? Color.white : Color.gray, lineWidth: 2)
                )
                .disabled(!isFileOpen)
                .fileExporter(isPresented: $isExporting, document: HydrogenSongFile(), contentType: .hydrogenSong) { result in
                    switch result {
                    case .success(let url):
                        try? convertor.saveHydrogenSong(url: url)

                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                }

                Spacer()

                Image("SmallLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 46)

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
//            if let fileURL = Bundle.module.url(forResource: "MIDI Files/Walkabout", withExtension: "mid") {
//                viewModel.loadSequencerFile(fileURL: fileURL)
//            }
        })
        .onDisappear(perform: {
            viewModel.stop()
            viewModel.stopEngine()
        })
        .environmentObject(viewModel)
}
}
