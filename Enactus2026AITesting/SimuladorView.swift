internal import SwiftUI
import SwiftData
import FirebaseFirestore
import FirebaseAuth

// MARK: - FirestoreMessageSender

actor FirestoreMessageSender {
    private lazy var db = Firestore.firestore()
    let agenteUID: String

    init(agenteUID: String) {
        self.agenteUID = agenteUID
    }

    func conversationId(para colaboradorUID: String) -> String {
        [colaboradorUID, agenteUID].sorted().joined(separator: "_")
    }

    func enviar(respuesta: String, a colaboradorUID: String) async {
        let convID = conversationId(para: colaboradorUID)
        let messageID = UUID().uuidString
        let ahora = Date()

        let messageData: [String: Any] = [
            "id": messageID,
            "senderId": agenteUID,
            "text": respuesta,
            "timestamp": Timestamp(date: ahora),
            "status": "sent",
            "reactions": [:]
        ]

        do {
            try await db
                .collection("conversations")
                .document(convID)
                .collection("messages")
                .document(messageID)
                .setData(messageData)

            try await db
                .collection("conversations")
                .document(convID)
                .setData([
                    "participants": [colaboradorUID, agenteUID].sorted(),
                    "lastMessage": respuesta,
                    "lastMessageTimestamp": Timestamp(date: ahora),
                    "lastMessageSenderId": agenteUID,
                    "unreadCount": FieldValue.increment(Int64(1))
                ], merge: true)

            print("[FirestoreMessageSender] ✅ → \(colaboradorUID): \(respuesta.prefix(60))…")
        } catch {
            print("[FirestoreMessageSender] ❌ Error: \(error)")
        }
    }
}

// MARK: - FirestoreConversationListener

final class FirestoreConversationListener {
    private lazy var db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var ultimoTimestamp: Date = Date()

    func iniciar(
        colaboradorUID: String,
        agenteUID: String,
        onMensajeRecibido: @escaping (String) async -> Void
    ) {
        let convID = [colaboradorUID, agenteUID].sorted().joined(separator: "_")
        let inicio = Timestamp(date: ultimoTimestamp)
        
        print("[Listener] convID: \(convID)")
        print("[Listener] colaboradorUID: \(colaboradorUID)")
        print("[Listener] agenteUID: \(agenteUID)")

        listener = db
            .collection("conversations")
            .document(convID)
            .collection("messages")
            .whereField("senderId", isEqualTo: colaboradorUID)
            .whereField("timestamp", isGreaterThan: inicio)
            .order(by: "timestamp")
            .addSnapshotListener { [weak self] snapshot, error in
                
                // 🔴 Error del listener
                if let error = error {
                    print("[Listener] ❌ Error: \(error.localizedDescription)")
                    return
                }
                
                // 📭 Snapshot nulo
                guard let snapshot = snapshot else {
                    print("[Listener] ⚠️ Snapshot nulo (sin error)")
                    return
                }
                
                print("[Listener] 🔔 Snapshot recibido — total docs: \(snapshot.documents.count), cambios: \(snapshot.documentChanges.count), fromCache: \(snapshot.metadata.isFromCache)")
                
                guard let self = self else {
                    print("[Listener] ⚠️ self ya fue liberado (weak self = nil)")
                    return
                }
                
                for change in snapshot.documentChanges {
                    let docID = change.document.documentID
                    let data  = change.document.data()
                    
                    print("[Listener] 📄 Cambio tipo: \(change.type == .added ? "added" : change.type == .modified ? "modified" : "removed") | docID: \(docID)")
                    
                    guard change.type == .added else {
                        print("[Listener] ↩️ Ignorado (no es .added)")
                        continue
                    }
                    
                    // Validar campo text
                    guard let texto = data["text"] as? String else {
                        print("[Listener] ⚠️ docID: \(docID) — 'text' ausente o no es String. data: \(data)")
                        continue
                    }
                    guard !texto.isEmpty else {
                        print("[Listener] ⚠️ docID: \(docID) — 'text' está vacío")
                        continue
                    }
                    
                    // Timestamp
                    if let ts = data["timestamp"] as? Timestamp {
                        let fecha = ts.dateValue()
                        print("[Listener] 🕐 docID: \(docID) — timestamp: \(fecha)")
                        self.ultimoTimestamp = fecha
                    } else {
                        print("[Listener] ⚠️ docID: \(docID) — 'timestamp' ausente o tipo inesperado: \(String(describing: data["timestamp"]))")
                    }
                    
                    print("[Listener] ✅ Disparando onMensajeRecibido — texto: \"\(texto)\"")
                    Task { await onMensajeRecibido(texto) }
                }
            }

    }

    func detener() {
        listener?.remove()
        listener = nil
    }
}

// MARK: - SimuladorView

struct SimuladorView: View {
    @Environment(\.modelContext) private var modelContext

    @StateObject private var orquestador: PipelineOrchestrator
    @State private var firestoreListener = FirestoreConversationListener()

    @State private var mensajeActual = ""
    @State private var colaboradorID = "aRpkP7AwTlg7Y8JkrDTwHbdfp043"
    @State private var historial: [TurnoConversacion] = []
    @State private var error: String?
    @State private var modoEscucha = false

    // UID dinámico desde Firebase Auth — se asigna al aparecer la vista
    @State private var agenteUID: String = Auth.auth().currentUser?.uid ?? "sin-autenticar"

    init(container: ModelContainer) {
        let uid = Auth.auth().currentUser?.uid ?? "sin-autenticar"
        _orquestador = StateObject(
            wrappedValue: PipelineOrchestrator(container: container, agenteUID: uid)
        )
    }

    var body: some View {
        VStack(spacing: 0) {

            // MARK: Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Simulador de conversación").font(.headline)
                    Text("ID: \(colaboradorID)").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()

                // Badge modo escucha Firestore
                if modoEscucha {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.green)
                            .frame(width: 7, height: 7)
                        Text("iMessage activo")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(.green.opacity(0.1), in: Capsule())
                }

                if let ruta = orquestador.ultimaRuta { RutaBadge(ruta: ruta) }

                // Toggle escucha Firestore
                Button(modoEscucha ? "Detener iMessage" : "Escuchar iMessage") {
                    modoEscucha ? detenerEscucha() : iniciarEscucha()
                }
                .buttonStyle(.borderless)
                .foregroundStyle(modoEscucha ? .red : .accentColor)

                Button("Nueva conv.") {
                    historial = []; orquestador.ultimaRuta = nil; error = nil
                }
                .buttonStyle(.borderless).foregroundStyle(.secondary)
            }
            .padding(16)
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            // MARK: Chat area
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
                                Text("O activa \"Escuchar iMessage\" para recibir mensajes reales")
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
                            withAnimation { proxy.scrollTo("procesando", anchor: .bottom) }
                        }
                    }
                }
            }

            // MARK: Error banner
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

            // MARK: Input area
            HStack(spacing: 12) {
                TextField("Escribe tu mensaje…", text: $mensajeActual, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)
                    .onSubmit { enviar() }

                Button(action: enviar) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(
                            mensajeActual.isEmpty || orquestador.procesando
                                ? .secondary : Color.accentColor
                        )
                }
                .buttonStyle(.plain)
                .disabled(mensajeActual.isEmpty || orquestador.procesando)
            }
            .padding(16)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .frame(minWidth: 600, minHeight: 500)
        .onAppear {
            // Actualiza el UID por si el auth completó después del init
            agenteUID = Auth.auth().currentUser?.uid ?? "sin-autenticar"
            print("[SimuladorView] Agente UID: \(agenteUID)")
        }
        .onDisappear { detenerEscucha() }
    }

    // MARK: - Firestore listener

    private func iniciarEscucha() {
        modoEscucha = true
        firestoreListener.iniciar(
            colaboradorUID: colaboradorID,
            agenteUID: agenteUID
        ) { textoRecibido in
            let turnoEntrada = TurnoConversacion(
                contenido: textoRecibido, esUsuario: true, timestamp: Date()
            )
            historial.append(turnoEntrada)

            do {
                let respuesta = try await orquestador.procesar(
                    mensaje: textoRecibido,
                    colaboradorID: colaboradorID,
                    historial: historial
                )
                historial.append(
                    TurnoConversacion(
                        contenido: respuesta.texto,
                        esUsuario: false,
                        timestamp: Date()
                    )
                )
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    private func detenerEscucha() {
        modoEscucha = false
        firestoreListener.detener()
    }

    // MARK: - Envío manual (input local)

    private func enviar() {
        let texto = mensajeActual.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !texto.isEmpty, !orquestador.procesando else { return }

        let mensajeUsuario = TurnoConversacion(contenido: texto, esUsuario: true, timestamp: Date())
        historial.append(mensajeUsuario)
        print("[SimuladorView] ✅ Mensaje usuario agregado: \(texto.prefix(50))")

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
                await MainActor.run {
                    historial.append(
                        TurnoConversacion(
                            contenido: respuesta.texto,
                            esUsuario: false,
                            timestamp: Date()
                        )
                    )
                    print("[SimuladorView] ✅ Total turnos: \(historial.count)")
                }
            } catch {
                print("[SimuladorView] ❌ Error: \(error.localizedDescription)")
                await MainActor.run { self.error = error.localizedDescription }
            }
        }
    }
}

// MARK: - BurbujaMensaje

struct BurbujaMensaje: View {
    let turno: TurnoConversacion

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if turno.esUsuario { Spacer(minLength: 80) }

            VStack(alignment: turno.esUsuario ? .trailing : .leading, spacing: 4) {
                Text(turno.contenido)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                turno.esUsuario
                                    ? Color.accentColor
                                    : Color(nsColor: .controlBackgroundColor)
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                turno.esUsuario
                                    ? Color.clear
                                    : Color.primary.opacity(0.1),
                                lineWidth: 1
                            )
                    )
                    .foregroundStyle(turno.esUsuario ? Color.white : Color.primary)
                    .textSelection(.enabled)
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)

                Text(turno.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            if !turno.esUsuario { Spacer(minLength: 80) }
        }
        .frame(maxWidth: .infinity, alignment: turno.esUsuario ? .trailing : .leading)
    }
}

// MARK: - RutaBadge

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
