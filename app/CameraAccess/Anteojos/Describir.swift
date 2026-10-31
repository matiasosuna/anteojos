//
// Describir.swift — Anteojos
//
// Manda la foto de los anteojos al Worker `anteojos-vision` (Cloudflare + Gemini)
// y lee la respuesta en voz alta. Si los anteojos están conectados por Bluetooth,
// la voz sale por sus parlantes.
//

import AVFoundation
import UIKit

@MainActor
enum Describir {
  static let url = URL(string: "https://anteojos-vision.osuna-devs.workers.dev/describir")!

  static func foto(_ imagen: UIImage) async throws -> String {
    guard let jpeg = achicar(imagen, lado: 1024).jpegData(compressionQuality: 0.7) else {
      throw Falla("No pude preparar la foto")
    }
    var pedido = URLRequest(url: url, timeoutInterval: 60)
    pedido.httpMethod = "POST"
    pedido.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
    pedido.setValue("Bearer \(Secretos.appToken)", forHTTPHeaderField: "Authorization")
    pedido.httpBody = jpeg

    let (data, _) = try await URLSession.shared.data(for: pedido)
    let respuesta = try JSONDecoder().decode(Respuesta.self, from: data)
    if let texto = respuesta.texto, !texto.isEmpty { return texto }
    throw Falla(respuesta.error ?? "No hubo respuesta")
  }

  private static func achicar(_ imagen: UIImage, lado: CGFloat) -> UIImage {
    let escala = min(1, lado / max(imagen.size.width, imagen.size.height))
    guard escala < 1 else { return imagen }
    let tamano = CGSize(width: imagen.size.width * escala, height: imagen.size.height * escala)
    return UIGraphicsImageRenderer(size: tamano).image { _ in
      imagen.draw(in: CGRect(origin: .zero, size: tamano))
    }
  }

  private struct Respuesta: Decodable {
    let texto: String?
    let error: String?
  }

  struct Falla: LocalizedError {
    let mensaje: String
    init(_ mensaje: String) { self.mensaje = mensaje }
    var errorDescription: String? { mensaje }
  }
}

/// Lee texto en voz alta en español.
@MainActor
final class Voz {
  static let shared = Voz()
  private let sintetizador = AVSpeechSynthesizer()

  func decir(_ texto: String) {
    sintetizador.stopSpeaking(at: .immediate)
    let frase = AVSpeechUtterance(string: texto)
    frase.voice =
      AVSpeechSynthesisVoice(language: "es-AR") ?? AVSpeechSynthesisVoice(language: "es-MX")
      ?? AVSpeechSynthesisVoice(language: "es-ES")
    sintetizador.speak(frase)
  }

  func callar() {
    sintetizador.stopSpeaking(at: .immediate)
  }
}
