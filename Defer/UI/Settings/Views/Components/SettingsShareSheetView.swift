import SwiftUI
import UIKit

struct SettingsShareSheetView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No dynamic updates required.
    }
}

#Preview {
    Text("Share sheet appears when exported backup is ready.")
        .padding()
}
