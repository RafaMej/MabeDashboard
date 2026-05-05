import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct IndexacionView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var chunks: [DocumentChunk]

    @State private var documentoID = "LFT-2024"
    @State private var estado: EstadoIndexacion = .idle
    @State private var resultado: IndexResult?
    @State private var isDragOver = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Indexación de documentos").font(.title2).fontWeight(.semibold)

            HStack {
                Text("ID documento:")
                TextField("ej. LFT-2024", text: $documentoID)
                    .textFieldStyle(.roundedBorder).frame(width: 200)
            }

            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isDragOver ? Color.accentColor : Color.secondary.opacity(0.4),
                              style: StrokeStyle(lineWidth: 2, dash: [6]))
                .frame(height: 140)
                .overlay {
                    VStack(spacing: 8) {
                        Image(systemName: "doc.badge.plus").font(.system(size: 36)).foregroundStyle(.secondary)
                        Text("Arrastra un PDF aquí").foregroundStyle(.secondary)
                        Button("O elige un archivo") { abrirPanel() }.buttonStyle(.borderless)
                    }
                }
                .onDrop(of: [.pdf], isTargeted: $isDragOver) { manejarDrop($0) }

            Group {
                switch estado {
                case .idle: EmptyView()
                case .indexando:
                    HStack(spacing: 10) {
                        ProgressView()
                        Text("Indexando…").foregroundStyle(.secondary)
                    }
                case .listo:
                    if let r = resultado {
                        Label(r.exitoso ? "Listo: \(r.resumen)" : "Con errores: \(r.resumen)",
                              systemImage: r.exitoso ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(r.exitoso ? .green : .orange)
                        .padding(12)
                        .background(.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                    }
                case .error(let msg):
                    Label(msg, systemImage: "xmark.circle.fill").foregroundStyle(.red)
                        .padding(12).background(.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Chunks en base de datos: \(chunks.count)").font(.headline)
                    Spacer()
                    if !chunks.isEmpty {
                        Button("Borrar todo", role: .destructive) { borrarTodo() }.buttonStyle(.borderless)
                    }
                }
                if chunks.isEmpty {
                    Text("Ningún documento indexado aún.").foregroundStyle(.secondary)
                } else {
                    let porDoc = Dictionary(grouping: chunks, by: \.documentID)
                    ForEach(porDoc.keys.sorted(), id: \.self) { docID in
                        HStack {
                            Image(systemName: "doc.text.fill").foregroundStyle(.tint)
                            Text(docID).fontWeight(.medium)
                            Spacer()
                            Text("\(porDoc[docID]!.count) chunks").foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            Spacer()
        }
        .padding(24)
    }

    private func abrirPanel() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        indexar(url: url)
    }

    private func manejarDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadFileRepresentation(forTypeIdentifier: UTType.pdf.identifier) { url, _ in
            guard let url else { return }
            let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
            try? FileManager.default.copyItem(at: url, to: tmp)
            DispatchQueue.main.async { self.indexar(url: tmp) }
        }
        return true
    }

    private func indexar(url: URL) {
        let id = documentoID.isEmpty ? url.deletingPathExtension().lastPathComponent : documentoID
        estado = .indexando
        Task {
            do {
                let indexer = DocumentIndexer(modelContainer: modelContext.container)
                let result = try await indexer.indexar(url: url, documentoID: id)
                await MainActor.run { resultado = result; estado = .listo }
            } catch {
                await MainActor.run { estado = .error(error.localizedDescription) }
            }
        }
    }

    private func borrarTodo() {
        chunks.forEach { modelContext.delete($0) }
        try? modelContext.save()
        resultado = nil; estado = .idle
    }
}

enum EstadoIndexacion: Equatable {
    case idle, indexando, listo
    case error(String)
}
