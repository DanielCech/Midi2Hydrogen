import SwiftUI

struct Midi2HydrogenNavBarTitle: ViewModifier {
    var text: String
    func body(content: Content) -> some View {
        content
        #if !os(macOS)
        .navigationBarTitle(Text(text))
        #endif
    }
}

extension View {
    func midi2HydrogenNavBarTitle(_ text: String) -> some View {
        modifier(Midi2HydrogenNavBarTitle(text: text))
    }
}
