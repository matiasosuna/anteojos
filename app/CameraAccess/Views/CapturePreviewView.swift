/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

//
// CapturePreviewView.swift
//
// Shared preview/share screen for captures from Meta wearable devices via the
// DAT SDK. Photos (Stream.capturePhoto()) and recorded videos use the same
// chrome — a media view plus Share and Close — so the two flows are consistent
// and captures aren't written straight to the library. Share hands the capture
// to the system share sheet, which includes "Save Image/Video" to Photos.
//

import AVKit
import SwiftUI

struct CapturePreviewView: View {
  let preview: CapturePreview
  let onDismiss: () -> Void

  @State private var player: AVPlayer?
  @State private var showShareSheet = false
  @State private var describiendo = false
  @State private var descripcion: String?

  init(preview: CapturePreview, onDismiss: @escaping () -> Void) {
    self.preview = preview
    self.onDismiss = onDismiss
    if case .video(let url) = preview {
      _player = State(initialValue: AVPlayer(url: url))
    }
  }

  var body: some View {
    ZStack {
      Color.black.opacity(0.9)
        .ignoresSafeArea()
        .onTapGesture { dismiss() }

      VStack(spacing: 24) {
        mediaView
          .frame(maxWidth: .infinity)
          .frame(height: 460)
          .clipShape(RoundedRectangle(cornerRadius: 12))
          .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)

        // Anteojos: descripción de la foto con Gemini, leída en voz alta.
        if case .photo = preview {
          descripcionView
        }

        HStack(spacing: 24) {
          if case .photo(let image) = preview {
            CircleButton(icon: "sparkles", text: "¿Qué es?") {
              describir(image)
            }
            .disabled(describiendo)
          }
          CircleButton(icon: "square.and.arrow.up", text: "Share") {
            showShareSheet = true
          }
          .accessibilityIdentifier("share_button")
        }
      }
      .padding()

      VStack {
        HStack {
          Spacer()
          CircleButton(icon: "xmark", text: nil) {
            dismiss()
          }
          .accessibilityIdentifier("close_preview_button")
          .padding(.trailing, 20)
          .padding(.top, 50)
        }
        Spacer()
      }
    }
    .onAppear {
      player?.play()
      // Apenas llega la foto, la describe sola.
      if case .photo(let image) = preview { describir(image) }
    }
    .sheet(isPresented: $showShareSheet) {
      ShareSheet(activityItems: [shareItem])
    }
  }

  @ViewBuilder
  private var mediaView: some View {
    switch preview {
    case .photo(let image):
      Image(uiImage: image)
        .resizable()
        .aspectRatio(contentMode: .fit)
    case .video:
      if let player {
        VideoPlayer(player: player)
      }
    }
  }

  private var shareItem: Any {
    switch preview {
    case .photo(let image): return image
    case .video(let url): return url
    }
  }

  @ViewBuilder
  private var descripcionView: some View {
    Group {
      if describiendo {
        ProgressView().tint(.white)
      } else if let descripcion {
        Text(descripcion)
          .font(.body)
          .foregroundStyle(.white)
          .multilineTextAlignment(.center)
      }
    }
    .frame(maxWidth: .infinity, minHeight: 44)
  }

  private func describir(_ image: UIImage) {
    describiendo = true
    Task {
      let texto: String
      do {
        texto = try await Describir.foto(image)
      } catch {
        texto = "No pude describirla: \(error.localizedDescription)"
      }
      descripcion = texto
      describiendo = false
      Voz.shared.decir(texto)
    }
  }

  private func dismiss() {
    player?.pause()
    Voz.shared.callar()
    onDismiss()
  }
}

struct ShareSheet: UIViewControllerRepresentable {
  let activityItems: [Any]

  func makeUIViewController(context: Context) -> UIActivityViewController {
    let activityViewController = UIActivityViewController(
      activityItems: activityItems,
      applicationActivities: nil
    )

    activityViewController.excludedActivityTypes = [
      .assignToContact,
      .addToReadingList,
    ]

    return activityViewController
  }

  func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
