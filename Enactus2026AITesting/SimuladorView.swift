internal import SwiftUI
import SwiftData

struct SimuladorView: View {
    @Environment(\.modelContext) private var modelContext

    @StateObject private var orquestador: PipelineOrchestrator
    @State private var mensajeActual = ""
    @State private var colaboradorID = "colab-001"
    @State private var historial: [TurnoConversacion] = []
    @State private var error: String?

    init(container: ModelContainer) {
        _orquestador = StateObject(wrappedValue: PipelineOrchestrator(container: container))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
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
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            // Chat area
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 16) {
                        if historial.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "bubble.left.and.bubble.right")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.tertiary)
                                Text("Escribe un mensaje para empezar")
                                    .foregroundStyle(.secondary)
                                Text("Prueba: \"¿Cuántos días de vacaciones me corresponden?\"")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 60)
                        } else {
                            ForEach(historial) { turno in
                                BurbujaMensaje(turno: turno)
                                    .id(turno.id)
                                    .onAppear {
                                        print("[SimuladorView] 🎨 Renderizando burbuja: \(turno.esUsuario ? "👤 Usuario" : "🤖 Asistente") - \(turno.contenido.prefix(40))")
                                    }
                            }
                        }
                        
                        if orquestador.procesando {
                            HStack(spacing: 8) {
                                ProgressView().scaleEffect(0.7)
                                Text("Procesando…")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .id("procesando")
                        }
                    }
                    .padding(20)
                }
                .background(Color(nsColor: .textBackgroundColor))
                .onChange(of: historial.count) { oldValue, newValue in
                    guard newValue > oldValue else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            if let lastID = historial.last?.id {
                                proxy.scrollTo(lastID, anchor: .bottom)
                            }
                        }
                    }
                }
                .onChange(of: orquestador.procesando) { _, procesando in
                    if procesando {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation {
                                proxy.scrollTo("procesando", anchor: .bottom)
                            }
                        }
                    }
                }
            }

            // Error banner
            if let err = error {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(err)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("OK") { error = nil }
                        .buttonStyle(.borderless)
                }
                .padding(10)
                .background(.orange.opacity(0.1))
                Divider()
            }

            // Input area
            HStack(spacing: 12) {
                TextField("Escribe tu mensaje…", text: $mensajeActual, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)
                    .onSubmit { enviar() }
                
                Button(action: enviar) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(mensajeActual.isEmpty || orquestador.procesando ? .secondary : Color.accentColor)
                }
                .buttonStyle(.plain)
                .disabled(mensajeActual.isEmpty || orquestador.procesando)
            }
            .padding(16)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .frame(minWidth: 600, minHeight: 500)
    }

    private func enviar() {
        let texto = mensajeActual.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !texto.isEmpty, !orquestador.procesando else { return }
        
        // Agregar mensaje del usuario al historial
        let mensajeUsuario = TurnoConversacion(contenido: texto, esUsuario: true, timestamp: Date())
        historial.append(mensajeUsuario)
        print("[SimuladorView] ✅ Mensaje usuario agregado: \(texto.prefix(50))")
        
        // Capturar el historial actualizado para pasarlo al orquestador
        let historialActualizado = historial
        
        mensajeActual = ""
        error = nil
        
        Task {
            do {
                let respuesta = try await orquestador.procesar(
                    mensaje: texto, 
                    colaboradorID: colaboradorID, 
                    historial: historialActualizado
                )
                
                print("[SimuladorView] ✅ Respuesta recibida: \(respuesta.texto.prefix(50))")
                
                // Agregar respuesta del asistente al historial en el MainActor
                await MainActor.run {
                    let respuestaAsistente = TurnoConversacion(
                        contenido: respuesta.texto, 
                        esUsuario: false, 
                        timestamp: Date()
                    )
                    historial.append(respuestaAsistente)
                    print("[SimuladorView] ✅ Burbuja de respuesta agregada al historial. Total: \(historial.count)")
                }
            } catch {
                print("[SimuladorView] ❌ Error: \(error.localizedDescription)")
                await MainActor.run { 
                    self.error = error.localizedDescription 
                }
            }
        }
    }
}

struct BurbujaMensaje: View {
    let turno: TurnoConversacion
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if turno.esUsuario {
                Spacer(minLength: 80)
            }
            
            VStack(alignment: turno.esUsuario ? .trailing : .leading, spacing: 4) {
                Text(turno.contenido)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(turno.esUsuario 
                                  ? Color.accentColor 
                                  : Color(nsColor: .controlBackgroundColor))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(turno.esUsuario 
                                        ? Color.clear
                                        : Color.primary.opacity(0.1), lineWidth: 1)
                    )
                    .foregroundStyle(turno.esUsuario 
                                   ? Color.white 
                                   : Color.primary)
                    .textSelection(.enabled)
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                
                Text(turno.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            
            if !turno.esUsuario {
                Spacer(minLength: 80)
            }
        }
        .frame(maxWidth: .infinity, alignment: turno.esUsuario ? .trailing : .leading)
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
