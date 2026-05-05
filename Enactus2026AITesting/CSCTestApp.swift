internal import SwiftUI
import SwiftData
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

// Test app - disabled @main (use NexusHRApp as main entry)
// @main
struct CSCTestApp: App {
    
    let container: ModelContainer = {
        let schema = Schema([
            DocumentChunk.self,
            ConversacionLog.self,
            Colaborador.self,
            Ticket.self
        ])
        let config = ModelConfiguration("csc-test", schema: schema)
        return try! ModelContainer(for: schema, configurations: config)
    }()
    
    init() {
        // Inicializa Firebase — requiere GoogleService-Info.plist en el bundle
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            AppRootView()
                .task { await arrancarApp() }
        }
        .modelContainer(container)
        .defaultSize(width: 1200, height: 750)
    }
    
    @MainActor
    private func arrancarApp() async {
        let context = container.mainContext
        await crearCuentaAgente()
        
        // 1. Sembrar colaboradores de prueba
        do {
            try ColaboradorSeeder.sembrarSiNecesario(context: context)
        } catch {
            print("[App] Error al sembrar colaboradores: \(error)")
        }
        
        // 2. Indexar documentos del bundle en background
        Task.detached(priority: .background) {
            do {
                let service = DocumentoIndexerService(modelContainer: container)
                let resultados = try await service.indexarTodosLosDocumentos()
                let total = resultados.values.reduce(0) { $0 + $1.chunksIndexados }
                print("[App] Indexación completa — \(total) chunks totales")
            } catch {
                print("[App] Error en indexación automática: \(error)")
            }
        }
    }
    
    private func crearCuentaAgente() async {
        do {
            let result = try await Auth.auth().signInAnonymously()
            let uid = result.user.uid
            print("[Agente] UID generado: \(uid)")   // ← cópialo de aquí
            
            // Crea el documento del agente en Firestore
            let db = Firestore.firestore()
            try await db.collection("users").document(uid).setData([
                "displayName": "Agente RRHH Mabe",
                "isTyping": false
            ])
        } catch {
            print("[Agente] Error: \(error)")
        }
    }
}
