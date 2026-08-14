import AppKit
import CoreImage
import CoreImage.CIFilterBuiltins
internal import UniformTypeIdentifiers

class ImageService {
    
    // Función para abrir el selector de archivos de macOS
    // TS: Esta función es asíncrona, devuelve una promesa que resuelve a la imagen
    
    private let context = CIContext()
    
    func selectImage() -> NSImage? {
        let panel = NSOpenPanel()
        
        // Configuración del panel (como el objeto de opciones en una lib de JS)
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.image]
        
        // Abrir el panel y esperar a que el usuario elija
        if panel.runModal() == .OK {
            if let url = panel.url {
                // Intentamos crear una NSImage desde la URL del disco
                return NSImage(contentsOf: url)
            }
        }
        
        return nil // El usuario canceló o hubo un error
    }
    // 1. Convertir NSImage a CIImage
    func applyProcessing(to image: NSImage, settings: EditorSettings) -> NSImage? {
        guard let tiffData = image.tiffRepresentation,
              let ciInput = CIImage(data: tiffData) else { return nil }
        
        // 2. Crear el filtro de Controles de Color (Brillo, Contraste, Saturación)

        let filter = CIFilter.colorControls()
                filter.inputImage = ciInput
                filter.brightness = Float(settings.brightness)
                filter.contrast = Float(settings.contrast)
                filter.saturation = Float(settings.saturation)
        
        // 3. Obtener la salida del filtro
        guard let outputCIImage = filter.outputImage else { return nil }
            
        // 4. Renderizar (Transformar la receta en píxeles reales usando la GPU)
        if let cgImage = context.createCGImage(outputCIImage, from: outputCIImage.extent) {
            return NSImage(cgImage: cgImage, size: image.size)
        }
        return nil
    }
}//
//  ImageService.swift
//  AZFluxEditor
//
//  Created by Eduardo Fabio Ayaviri Zuna on 13/08/2026.
//

