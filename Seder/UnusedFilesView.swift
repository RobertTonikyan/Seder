import SwiftUI

/// The "Unused Files" window: a table of old files you can move to the Trash.
struct UnusedFilesView: View {
    @StateObject private var model = UnusedFilesModel()
    @State private var isConfirmingTrash = false

    var body: some View {
        VStack(spacing: 0) {
            topBar
            Divider()
            table
            Divider()
            bottomBar
        }
        .frame(minWidth: 720, minHeight: 440)
        .onAppear { model.scan() }
        .confirmationDialog(
            "Move \(model.selection.count) file(s) to the Trash?",
            isPresented: $isConfirmingTrash
        ) {
            Button("Move to Trash", role: .destructive) {
                model.moveSelectedToTrash()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("You can still restore them from the Trash.")
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            Picker("Not opened in", selection: $model.days) {
                Text("7 days").tag(7)
                Text("14 days").tag(14)
                Text("30 days").tag(30)
                Text("60 days").tag(60)
                Text("90 days").tag(90)
            }
            .frame(width: 220)

            Spacer()

            Text(model.message)
                .foregroundStyle(.secondary)

            Button("Rescan") {
                model.scan()
            }
        }
        .padding(12)
    }

    private var table: some View {
        Table(model.files, selection: $model.selection) {
            TableColumn("Name", value: \.name)

            TableColumn("Location", value: \.location)

            TableColumn("Last Opened") { file in
                Text(file.lastUsed, format: .relative(presentation: .named))
            }
            .width(min: 110, ideal: 130)

            TableColumn("Size") { file in
                Text(ByteCountFormatter.string(fromByteCount: file.size, countStyle: .file))
            }
            .width(min: 70, ideal: 80)
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            Text(model.selection.isEmpty
                 ? "Select files (⌘A selects all)"
                 : "\(model.selection.count) selected · \(model.selectedSizeText)")
                .foregroundStyle(.secondary)

            Spacer()

            Button("Reveal in Finder") {
                model.revealSelected()
            }
            .disabled(model.selection.isEmpty)

            Button("Move to Trash…", role: .destructive) {
                isConfirmingTrash = true
            }
            .disabled(model.selection.isEmpty)
        }
        .padding(12)
    }
}
