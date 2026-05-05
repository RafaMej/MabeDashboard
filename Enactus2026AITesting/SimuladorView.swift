import SwiftUI
import SwiftData

struct SimuladorView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ConversacionLog.timestamp, order: .reverse)
    private var logs: [ConversacionLog]

    @StateObject private var orquestador: PipelineOrchestrator
    @State private var mensajeActual = ""
    @State private var colaboradorID = "colab-001"
    @State private var historial: [TurnoConversacion] = []
    @State private var error: String?

    init(container: ModelContainer) {
        _orquestador = StateObject(wrappedValue: PipelineOrchestrator(container: container))
    }

    var body: some View {
        HSplitView {
            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Simulador de conversación").font(.headline)
                        Text("ID: \(colaboradorID)").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    if let ruta = orquestador.ultimaRuta { RutaBadge(ruta: ruta) }
                    Button("Nueva conv.") {
                        historial = []; orquestador.ultimaRuta = nil; error = nil
                    }
                    .buttonStyle(.borderless).foregroundStyle(.secondary)
                }
                .padding(16)

                Divider()

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            if historial.isEmpty {
                                VStack(spacing: 8) {
                                    Image(systemName: "bubble.left.and.bubble.right")
                                        .font(.system(size: 40)).foregroundStyle(.tertiary)
                                    Text("Escribe un mensaje para empezar")
                                        .foregroundStyle(.secondary)
                                    Text("Prueba: \"¿Cuántos días de vacaciones me corresponden?\"")
                                        .font(.caption).foregroundStyle(.tertiary)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity).padding(.top, 60)
                            }
                            ForEach(historial) { turno in
                                BurbujaMensaje(turno: turno).id(turno.id)
                            }
                            if orquestador.procesando {
                                HStack(spacing: 8) {
                                    ProgressView().scaleEffect(0.7)
                                    Text("Procesando…").font(.caption).foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 16).id("procesando")
                            }
                        }
                        .padding(16)
                    }
                    .onChange(of: historial.count) { _, _ in
                        withAnimation { 
                            if let lastID = historial.last?.id {
                                proxy.scrollTo(lastID)
                            } else if orquestador.procesando {
                                proxy.scrollTo("procesando")
                            }
                        }
                    }
                }

                if let err = error {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                        Text(err).font(.caption).foregroundStyle(.secondary)
                        Spacer()
                        Button("OK") { error = nil }.buttonStyle(.borderless)
                    }
                    .padding(10).background(.orange.opacity(0.1))
                }

                Divider()

                HStack(spacing: 10) {
                    TextField("Escribe como colaborador…", text: $mensajeActual, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...4)
                        .onSubmit { enviar() }
                    Button { enviar() } label: {
                        Image(systemName: "arrow.up.circle.fill").font(.system(size: 28))
                    }
                    .buttonStyle(.borderless)
                    .disabled(mensajeActual.isEmpty || orquestador.procesando)
                }
                .padding(12)
            }
            .frame(minWidth: 420)

            VStack(alignment: .leading, spacing: 0) {
                Text("Log de conversaciones (\(logs.count))").font(.headline).padding(16)
                Divider()
                if logs.isEmpty {
                    ContentUnavailableView("Sin logs", systemImage: "tray",
                        description: Text("Los logs aparecen al enviar mensajes."))
                } else {
                    List(logs) { log in LogRow(log: log) }.listStyle(.inset)
                }
            }
            .frame(minWidth: 300)
        }
    }

    private func enviar() {
        let texto = mensajeActual.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !texto.isEmpty, !orquestador.procesando else { return }
        historial.append(TurnoConversacion(contenido: texto, esUsuario: true, timestamp: Date()))
        mensajeActual = ""
        error = nil
        Task {
            do {
                let respuesta = try await orquestador.procesar(
                    mensaje: texto, colaboradorID: colaboradorID, historial: historial)
                historial.append(TurnoConversacion(
                    contenido: respuesta.texto, esUsuario: false, timestamp: Date()))
            } catch {
                await MainActor.run { self.error = error.localizedDescription }
            }
        }
    }
}

struct BurbujaMensaje: View {
    let turno: TurnoConversacion
    var body: some View {
        HStack {
            if turno.esUsuario { Spacer(minLength: 60) }
            Text(turno.contenido)
                .padding(10)
                .background(turno.esUsuario ? Color.accentColor : Color.secondary.opacity(0.15),
                            in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(turno.esUsuario ? .white : .primary)
            if !turno.esUsuario { Spacer(minLength: 60) }
        }
    }
}

struct RutaBadge: View {
    let ruta: RutaAgente
    var color: Color {
        switch ruta {
        case .simple:   return .green
        case .sensible: return .orange
        case .escalar:  return .red
        }
    }
    var body: some View {
        Text(ruta.rawValue.uppercased())
            .font(.caption.bold())
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
    }
}

struct LogRow: View {
    let log: ConversacionLog
    var modoColor: Color {
        switch log.modo {
        case "simple":   return .green
        case "sensible": return .orange
        default:         return .red
        }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Circle().fill(modoColor).frame(width: 8, height: 8)
                Text(log.modo).font(.caption.bold()).foregroundStyle(modoColor)
                Spacer()
                Text(log.timestamp, style: .time).font(.caption2).foregroundStyle(.tertiary)
            }
            Text(log.mensajeEntrada).font(.caption).lineLimit(1).foregroundStyle(.secondary)
            HStack(spacing: 8) {
                Label(log.resuelta ? "Resuelta" : "Escalada",
                      systemImage: log.resuelta ? "checkmark" : "arrow.up.right")
                    .font(.caption2).foregroundStyle(log.resuelta ? .green : .red)
                Text(String(format: "%.2fs", log.duracionSegundos))
                    .font(.caption2).foregroundStyle(.tertiary)
                Text("confianza: \(String(format: "%.0f%%", log.scoreConfianza * 100))")
                    .font(.caption2).foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}
