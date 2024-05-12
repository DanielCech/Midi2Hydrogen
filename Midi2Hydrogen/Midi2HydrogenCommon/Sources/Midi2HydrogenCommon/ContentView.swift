import AudioKit
import AudioKitEX
import AudioKitUI
import SwiftUI
import UniformTypeIdentifiers

public struct ContentView: View {
    @ObservedObject var viewModel = ContentViewModel()
    @StateObject var trackViewModel = MIDITrackViewModel()

    @State var fileURL: URL?
    @State var isPlaying = false
    @State private var isImportingMidi: Bool = false
    @State private var isImportingDrumkit: Bool = false
    @State private var isExporting: Bool = false
    @State private var isLoadingMapping: Bool = false
    @State private var isSavingMapping: Bool = false
    @State private var isFileOpen: Bool = false
    @State private var showAbout: Bool = false

    @State private var document = HydrogenSongFile()

    @State var selectedTrack: String?
    //    @State var instrumentMapping = [Int: String]()

    var selectedTrackInt: Int {
        Int(selectedTrack ?? "0") ?? 0
    }

    public init() {
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                openMidiButton()
                    .padding()

                Image("Arrow1")

                openDrumkitFromSongButton()
                    .padding()

                Image("Arrow2")

                convertButton()
                    .padding()

                Spacer()

                Image("SmallLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 46)
                    .padding()
                    .onTapGesture {
                        showAbout = true
                    }
                    .alert("MIDI2Hydrogen by Daniel Cech\n\nhttps://github.com/DanielCech/Midi2Hydrogen", isPresented: $showAbout, actions: {})
            }

            Color.gray
                .opacity(0.5)
                .frame(height: 1)

            HStack() {
                midiTrackView()
                    .onTapGesture {
                        isPlaying.toggle()
                    }

                Color.gray
                    .opacity(0.5)
                    .frame(width: 1)

                instrumentMappingView()
            }



        }
        .padding(.zero)
        .background(
            Image("Background")
                .resizable(resizingMode: .stretch)
        )
        .navigationBarTitle(Text("Midi2Hydrogen"))
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


    private func openMidiButton() -> some View {
        Button(
            action: {
            isImportingMidi = true
            },
            label: {
                Text("Open MIDI File...")
                    .padding()
                    .foregroundColor(.white)
                    .backgroundStyle(.gray.opacity(0.1))
                    .background {
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Color.white, lineWidth: 2)
                    }
                    .contentShape(Rectangle())
                    .fileImporter(isPresented: $isImportingMidi,
                                  allowedContentTypes: [.midi],
                                  onCompletion: { result in

                        switch result {
                        case .success(let url):
                            isFileOpen = true
                            fileURL = url
                            trackViewModel.loadSequencerFile(fileURL: url)
                            viewModel.openFile(url: url)
                            selectedTrack = "0"
                            viewModel.preprocessSelectedTrack(track: 0)


                        case .failure(let error):
                            print(error)
                        }
                    }
                )
            }
        )
    }

    private func openDrumkitFromSongButton() -> some View {
        Button(
            action: {
                isImportingDrumkit = true
            },
            label: {
                Text("Drumkit from Song...")
                    .padding()
                    .foregroundColor(.white)
                    .backgroundStyle(.gray.opacity(0.1))
                    .background {
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(Color.white, lineWidth: 2)
                    }
                    .contentShape(Rectangle())
                    .fileImporter(isPresented: $isImportingDrumkit,
                                  allowedContentTypes: [.hydrogenSong],
                                  onCompletion: { result in

                        switch result {
                        case .success(let url):
                            viewModel.loadDrumkit(url: url)

                        case .failure(let error):
                            print(error)
                        }
                    }
                )
            }
        )
    }

    private func convertButton() -> some View {
        Button(
            action: {
            isImportingMidi = true
            },
            label: {
                Text("Convert to Hydrogen Song...")
                    .padding()
                    .foregroundColor(isFileOpen ? .white : .gray)
                    .backgroundStyle(.gray.opacity(0.1))
                    .background {
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(isFileOpen ? Color.white : Color.gray, lineWidth: 2)
                    }
                    .contentShape(Rectangle())
                    .fileExporter(isPresented: $isExporting, document: HydrogenSongFile(), contentType: .hydrogenSong, defaultFilename: fileURL?.lastPathComponent.withoutExtension) { result in
                        switch result {
                        case .success(let url):
                            viewModel.convert(track: selectedTrackInt)
                            try? viewModel.saveHydrogenSong(url: url)

                        case .failure(let error):
                            print(error.localizedDescription)
                        }
                    }
            }
        )
        .disabled(!isFileOpen)
    }

    private func midiTrackView() -> some View {
        GeometryReader { geometry in
            VStack(alignment: .center, spacing: 0) {
                Spacer()

                if fileURL != nil {
                    Text("MIDI Track View:")
                        .padding(.top, 10)

                    MIDITrackView(fileURL: $fileURL,
                                  trackNumber: selectedTrackInt,
                                  trackWidth: geometry.size.width - 40,
                                  trackHeight: 200.0)
                    .background(Color.primary)
                    .cornerRadius(10.0)
                    .padding()
                } else {
                    Color.clear
                        .frame(height: 200)
                        .padding()
                }

                Spacer()

                Text("General MIDI mapping from GuitarPro:")
                Image("DrumKit")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(10.0)
                    .frame(height: 678)
                    .padding()

            }
        }
    }



private func instrumentMappingView() -> some View {
    Form {
        if viewModel.tracks.isNotEmpty {
            Section {
                Picker(selection: $selectedTrack, label: Text("MIDI Track")) {
                    Text("No Chosen Item").tag(nil as String?)
                    ForEach(viewModel.tracks, id: \.self) { trackNumber in
                        Text(trackNumber).tag(trackNumber as String?)
                    }
                }
                //                    .onChange(of: selectedTrack) { trackString in
                //                        if let trackInt = Int(trackString) {
                //                            viewModel.preprocessSelectedTrack(track: trackInt)
                //                        }
                //                    }
            }
        }

        Section {
            TextEditor(text: $viewModel.drumkit)

            TextEditor(text: $viewModel.drumkitPath)
                .frame(height: 100)
        }

        Section {
            ForEach(viewModel.midiInstruments, id: \.self) { midiInstrument in
                Picker(selection: $viewModel.instrumentMapping[midiInstrument], label: Text("\(midiInstrument):")) {
                    Text("No Chosen Item").tag(nil as String?)
                    ForEach(viewModel.drumkitInstruments, id: \.self) { item in
                        Text(item).tag(item as String?)
                    }
                }

            }

        }

        Section {
            Button("Load Mapping...") {
                isLoadingMapping = true
            }
            .fileImporter(isPresented: $isLoadingMapping, allowedContentTypes: [.json]) { result in
                switch result {
                case .success(let url):
                    try? viewModel.loadMapping(url: url)

                case .failure(let error):
                    print(error.localizedDescription)
                }
            }

            Button("Save Mapping...") {
                isSavingMapping = true
            }
            .disabled(viewModel.midiInstruments.isEmpty)
            .fileExporter(isPresented: $isSavingMapping, document: HydrogenSongFile(), contentType: .json, defaultFilename: fileURL?.lastPathComponent.withoutExtension) { result in
                switch result {
                case .success(let url):
                    try? viewModel.saveMapping(url: url)

                case .failure(let error):
                    print(error.localizedDescription)
                }
            }

        }

    }
    .scrollContentBackground(.hidden)
    .frame(width: 310)
}
}
