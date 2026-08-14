import SwiftUI      // Importamos SwiftUI porque usaremos @Published y tipos de imagen
import Combine // El framework de "eventos" de Apple

// 'ObservableObject' es un protocolo que dice: "Esta clase puede emitir anuncios cuando algo cambia"
class EditorViewModel: ObservableObject {
    @Published var settings = EditorSettings()
    @Published var processedImage: NSImage? = nil
    @Published var isLoading: Bool = false
    
    private var originalImage: NSImage? = nil
    private let imageService = ImageService()
    
    func pickImage() {
        if let selectedImage = imageService.selectImage() {
            self.originalImage = selectedImage
            self.processedImage = selectedImage
            // Resetear ajustes al cargar imagen nueva
            self.settings = EditorSettings()
        }
    }

    // --- NUEVA FUNCIÓN ---
    func updateImage() {
        guard let original = originalImage else { return }
        
        // Procesamos en un hilo secundario para no congelar la interfaz
        // TS: Similar a un Worker o una operación async pesada
        DispatchQueue.global(qos: .userInteractive).async {
            let result = self.imageService.applyProcessing(to: original, settings: self.settings)
            
            DispatchQueue.main.async {
                self.processedImage = result
            }
        }
    }
}
