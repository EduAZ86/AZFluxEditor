import SwiftUI

struct BasicEditingView: View {
    @ObservedObject var viewModel: EditorViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            CustomSlider(
                label: "Brillo",
                value: $viewModel.settings.brightness,
                range: -1...1
            )
            
            CustomSlider(
                label: "Contraste",
                value: $viewModel.settings.contrast,
                range: 0.25...4
            )
            
            CustomSlider(
                label: "Saturación",
                value: $viewModel.settings.saturation,
                range: 0...2
            )
        }
        // Cuando cualquier valor de settings cambie, actualizamos la imagen
        .onChange(of: viewModel.settings.brightness) { _ in viewModel.updateImage() }
        .onChange(of: viewModel.settings.contrast) { _ in viewModel.updateImage() }
        .onChange(of: viewModel.settings.saturation) { _ in viewModel.updateImage() }
    }
}//

