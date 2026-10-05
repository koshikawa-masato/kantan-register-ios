import SwiftUI

@main struct KantanRegisterApp: App {
    @StateObject private var store = ProcessInfo.processInfo.arguments.contains("--uitesting") ? RegisterStore(fileURL: nil) : RegisterStore()
    var body: some Scene { WindowGroup { ContentView().environmentObject(store).preferredColorScheme(.light) } }
}
