import Foundation

// Definimos un Model como un struct (Tipo de valor)
struct EditorSettings {
    var brightness: Double = 0.0  // Rango típico: -1.0 a 1.0
    var contrast: Double = 1.0    // Rango típico: 0.25 a 4.0
    var saturation: Double = 1.0  // Rango típico: 0.0 a 2.0
    var temperature: Double = 0.5
    // Aquí es donde en el futuro añadiremos el "Prompt" para Flux
    var aiPrompt: String = ""
    var aiStrength: Double = 0.5
}//
//  EditorSettings.swift
//  AZFluxEditor
//
//  Created by Eduardo Fabio Ayaviri Zuna on 13/08/2026.
//

