import SwiftUI
import UIKit

/// Raiz do painel convertido de aplicativo independente para módulo hospedado.
struct TriggerPanelHost: View {
    @StateObject private var appState = AppState()
    @StateObject private var patchDraftCoordinator = PatchDraftCoordinator()
    @StateObject private var fileOperationCoordinator = FileOperationCoordinator()
    @StateObject private var patchStore = PatchProjectStore()
    @StateObject private var repositoryStore = PackageRepositoryStore()

    var body: some View {
        ContentView()
            .environmentObject(appState)
            .environmentObject(patchDraftCoordinator)
            .environmentObject(fileOperationCoordinator)
            .environmentObject(patchStore)
            .environmentObject(repositoryStore)
            .environment(\.appLanguage, .portuguese)
            .environment(\.locale, AppLanguage.portuguese.locale)
    }
}

final class TriggerPresentationCoordinator {
    static let shared = TriggerPresentationCoordinator()

    private weak var presentedController: UIViewController?
    private var isPresenting = false

    private init() {}

    func presentPanelIfNeeded() {
        guard !isPresenting else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self, !self.isPresenting else { return }
            guard let presenter = self.topViewController() else { return }

            let controller = UIHostingController(rootView: TriggerPanelHost())
            controller.modalPresentationStyle = .pageSheet
            controller.title = "3105"
            if let sheet = controller.sheetPresentationController {
                sheet.detents = [.large()]
                sheet.prefersGrabberVisible = true
            }

            self.isPresenting = true
            self.presentedController = controller
            presenter.present(controller, animated: true)
        }
    }

    func dismissPanelIfPresented() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }\
            self.presentedController?.dismiss(animated: true)
            self.presentedController = nil
            self.isPresenting = false
        }
    }

    // Usa UIWindowScene em vez de UIApplication.shared.windows
    // (deprecated no iOS 15, removido no iOS 26)
    private func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }

        let window = scene?.windows.first { $0.isKeyWindow }
            ?? scene?.windows.first

        var current = window?.rootViewController
        while let presented = current?.presentedViewController {
            current = presented
        }
        return current
    }
}
