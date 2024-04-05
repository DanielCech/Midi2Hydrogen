import AudioKit
import AudioKitEX
import AudioKitUI
import SwiftUI
import UniformTypeIdentifiers

public struct ContentView: View {
    @ObservedObject var viewModel = ContentViewModel()
    @StateObject var trackViewModel = MIDITrackViewModel()
    @StateObject var convertor = Convertor()
    
    @State var fileURL: URL? // = Bundle.module.url(forResource: "MIDI Files/Walkabout", withExtension: "mid")
    @State var isPlaying = false
    @State private var isImporting: Bool = false
    @State private var isExporting: Bool = false
    @State private var isFileOpen: Bool = false

    @State private var drumkitPath: String = ""

    @State private var document = HydrogenSongFile()

    @State var selectedPickerItem: String?
    var pickerItems = ["item 1",
                       "item 2",
                       "item 3",
                       "item 4",
                       "item 5",
                       "item 6"]

    public init() {

    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                openButton()
                    .padding()

                convertButton()
                    .padding()

                Spacer()

                Image("SmallLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 46)
                    .padding()
            }

            Color.gray
                .frame(height: 1)

            HStack() {
                midiTrackView()

                Color.gray
                    .frame(width: 1)

                instrumentMapping()
            }

            

        }
        .padding(.zero)
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
                trackViewModel.play()
            } else {
                trackViewModel.stop()
            }
        })
        .onAppear(perform: {
            trackViewModel.startEngine()
        })
        .onDisappear(perform: {
            trackViewModel.stop()
            trackViewModel.stopEngine()
        })
        .environmentObject(trackViewModel)
    }


    private func openButton() -> some View {
        Button("Open MIDI File...") {
            isImporting = true
        }
        .padding()
        .foregroundColor(.white)
        .backgroundStyle(.gray.opacity(0.1))
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
                trackViewModel.loadSequencerFile(fileURL: url)
                convertor.openFile(url: url)

            case .failure(let error):
                print(error)
            }
        })
    }

    private func convertButton() -> some View {
        Button("Convert to Hydrogen Song") {
            isExporting = true
        }
        .padding()
        .foregroundColor(isFileOpen ? .white : .gray)
        .backgroundStyle(.gray.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .stroke(isFileOpen ? Color.white : Color.gray, lineWidth: 2)
        )
        .disabled(!isFileOpen)
        .fileExporter(isPresented: $isExporting, document: HydrogenSongFile(), contentType: .hydrogenSong, defaultFilename: fileURL?.lastPathComponent.withoutExtension) { result in
            switch result {
            case .success(let url):
                try? convertor.saveHydrogenSong(url: url)

            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }

    private func midiTrackView() -> some View {
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
            .padding(.top, 250)


    }


    private func instrumentMapping() -> some View {
        Form {
            Section {
                TextField("Drumkit path", text: $drumkitPath)
            }

            Section {
                ForEach(viewModel.mappings, id: \.self) { mapping in

                    Picker(selection: $selectedPickerItem, label: Text("\(mapping):")) {
                                Text("No Chosen Item").tag(nil as String?)
                                ForEach(pickerItems, id: \.self) { item in
                                    Text(item).tag(item as String?)
                                }
                            }

                }

            }

        }
        .scrollContentBackground(.hidden)
        .frame(width: 310)
    }
}
