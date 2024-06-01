//
//  PuzzleTileView.swift
//  YouAreThePuzzle
//
//  Created by Heical Chandra on 31/05/24.
//

import SwiftUI

struct PuzzleTileView: View {
    let tile: PuzzleTile
    var body: some View {
        VStack{
            if let image = tile.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Color.yellow
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 5)
                .stroke(Color.yellow, lineWidth: 2)
        }
        .clipShape(RoundedRectangle(cornerRadius: 5))
    }
}

#Preview {
    PuzzleTileView(tile: PuzzleTile(image: nil, isSpareTile: true))
}
