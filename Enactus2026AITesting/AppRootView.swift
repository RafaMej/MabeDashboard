import SwiftUI
import SwiftData

struct AppRootView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationSplitView {
            List {
                NavigationLink("Indexación",        destination: IndexacionView())
                NavigationLink("Búsqueda RAG",      destination: BusquedaView())
                NavigationLink("Simulador de chat", destination: SimuladorView(container: modelContext.container))
            }
            .navigationTitle("CSC · Pruebas")
        } detail: {
            SimuladorView(container: modelContext.container)
        }
    }
}
