import SwiftUI

struct MainView: View {
    
    @StateObject private var viewModel = EditorViewModel()
    
    var body: some View {
        NavigationSplitView {
            // LADO IZQUIERDO: Controles (Sidebar)
            sidebar
                .navigationSplitViewColumnWidth(min: 250, ideal: 300)
        } detail: {
            // LADO DERECHO: El Lienzo (Canvas)
            canvas
        }
        .frame(minWidth: 800, minHeight: 600)
    }
    
    // MARK: - Componentes
    
    private var sidebar: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                Text("AZ Flux Editor")
                    .font(.system(size: 24, weight: .bold))
                
                // Simplemente llamamos a la Feature
                BasicEditingView(viewModel: viewModel)
                
                Divider()
                
                // Aquí irá: AIEditingView(viewModel: viewModel)
                
                Spacer()
            }
            .padding()
        }
    }
    
    private var canvas: some View {
        ZStack {
            Color.black.opacity(0.1) // Fondo gris claro
            
            if let image = viewModel.processedImage {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding()
                    .shadow(radius: 10)
            } else {
                VStack {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 50))
                    Text("No hay imagen seleccionada")
                        .padding()
                    Button("Seleccionar Imagen") {
                        viewModel.pickImage()
                    }
                }
                .foregroundColor(.secondary)
            }
            
            if viewModel.isLoading {
                ProgressView() // Spinner de carga
                    .background(.ultraThinMaterial)
                    .cornerRadius(10)
            }
        }
    }
}
