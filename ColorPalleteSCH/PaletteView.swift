//
//  PaletteView.swift
//  ColorPalleteSCH
//
//  Created by seyedeh sepideh sadeghi far on 10/02/26.
//

import SwiftUI

// This view displays the AI Generated Result
@available(iOS 26.0, *)
struct PaletteView: View {
    let palette: ColorPalette // Uses the Generated Model

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(palette.title)
                .font(.title2.bold())

            ForEach(palette.colors, id: \.hex) { color in
                HStack(spacing: 16) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: color.hex))
                        .frame(width: 56, height: 56)
                        .shadow(radius: 2)

                    VStack(alignment: .leading) {
                        Text(color.name).font(.headline)
                        Text(color.hex).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}
