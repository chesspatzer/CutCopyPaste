import Foundation
import Combine

#if !APPSTORE
import Sparkle
#endif

@MainActor
final class UpdaterService: ObservableObject {
    static let shared = UpdaterService()

    #if !APPSTORE
    private let updaterController: SPUStandardUpdaterController
    @Published var canCheckForUpdates = false
    private var cancellable: AnyCancellable?

    private init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        cancellable = updaterController.updater.publisher(for: \.canCheckForUpdates)
            .receive(on: RunLoop.main)
            .assign(to: \.canCheckForUpdates, on: self)
    }

    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }

    var automaticallyChecksForUpdates: Bool {
        get { updaterController.updater.automaticallyChecksForUpdates }
        set { updaterController.updater.automaticallyChecksForUpdates = newValue }
    }
    #else
    @Published var canCheckForUpdates = false

    private init() {}

    func checkForUpdates() {}
    #endif
}
