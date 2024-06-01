//
//  ContentView.swift
//  YouAreThePuzzle
//
//  Created by Heical Chandra on 31/05/24.
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var puzzleImage: UIImage?
    @State private var orderedTiles: [[PuzzleTile]]?
    @State private var shuffledTiles: [[PuzzleTile]]?
    @State private var userWon = false
    @State private var LoadingImage = false
    @State private var loadedPuzzle = false
    @State private var showHint = false
    @State private var moves = 0
    private let tileSpacing = 5.0
    
    var body: some View {
        NavigationView{
            VStack{
                if loadedPuzzle, let shuffledTiles, let puzzleImage {
                    HStack(spacing: nil, content: {
                        movesCountView()
                        
                        Spacer()
                        puzzleHintToogleView()
                        
                        changePhotoView()
                    })
                    .padding([.top, .horizontal], 20)
                    .font(.system(size: 20))
                    puzzleHintView(puzzleImage)
                    puzzleView(shuffledTiles)
                        .padding()
                        .alert("You Win", isPresented: $userWon){
                            
                        }
                } else {
                    emptyPuzzleView()
                }
            }
            .background{
                Color.white.ignoresSafeArea()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                if loadedPuzzle{
                    ToolbarItem(placement: .topBarLeading){
                        closeButtonView()
                    }
                }
                ToolbarItem(placement: .principal){
                    titleView()
                }
            })
        }
        .foregroundStyle(.white)
        .font(.title)
    }
    @ViewBuilder private func closeButtonView() -> some View {
        Button(action: {
            reset()
            selectedPhotoItem = nil
        }){
            Image(systemName: "xmark.circle.fill")
                .font(.body)
                .foregroundLinearGradient(colors: [Color.yellow, Color.orange], startPoint: .top, endPoint: .bottom)
        }
    }
    @ViewBuilder private func titleView() -> some View {
        HStack{
            Image(systemName: "puzzlepiece.fill")
            Text("Piczle")
                .font(.custom("Noteworthy Bold", size: 30))
        }
        .foregroundLinearGradient(colors: [Color.yellow, Color.orange], startPoint: .top, endPoint: .bottom)
    }
    @ViewBuilder private func emptyPuzzleView() -> some View {
        Group {
            if LoadingImage {
                Text("loading")
                    .bold()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            } else {
                ContentUnavailableView(label: {
                    Text("No image Selected")
                        .bold()
                }, description: {
                    Text("Click the button below to pick one")
                }, actions: {
                    PhotoPickerView()
                        .foregroundStyle(Color.yellow)
                })
            }
        }
        .foregroundStyle(Color.orange)
    }
    @ViewBuilder private func PhotoPickerView() -> some View {
        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
            Image(systemName: "photo")
        }
        .onChange(of: selectedPhotoItem) { oldValue, newValue in
            Task {
                if let selectedPhotoItem {
                    reset()
                    LoadingImage = true
                    loadedPuzzle = true
                    
                    do {
                        
                        let (image, tiles) = try await PuzzleLoader().LoadPuzzleFromItem(selectedPhotoItem)
                        puzzleImage = image
                        orderedTiles = tiles.0
                        shuffledTiles = tiles.1
                        loadedPuzzle = true
                    } catch {
                        loadedPuzzle = false
                        print(error.localizedDescription)
                    }
                    LoadingImage = false
                }
            }
        }
    }
    @ViewBuilder private func puzzleView(_ tiles: [[PuzzleTile]]) -> some View {
        GeometryReader(content: { geometry in
            VStack(spacing: tileSpacing){
                ForEach(0..<3, id: \.self) { row in
                    HStack(spacing: tileSpacing){
                        ForEach(0..<3, id: \.self) { column in
                            let tile = tiles[row][column]
                            PuzzleTileView(tile: tile)
                                .frame(width: (geometry.size.width - (tileSpacing*2)) / 3,
                                       height:(geometry.size.width - (tileSpacing*2)) / 3)
                                .onTapGesture{
                                    tappedTile(row: row, column: column)
                                }
                        }
                    }
                }
            }
        })
    }
    @ViewBuilder private func puzzleHintView(_ image: UIImage) -> some View{
        if showHint {
            PuzzleTileView(tile: PuzzleTile(image: image))
                .frame(width: 200, height: 200)
                .animation(.linear, value: showHint)
        }
    }
    
    @ViewBuilder private func movesCountView() -> some View {
        VStack(alignment: .leading){
            HStack{
                Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                Text("\(moves)")
                    .monospaced()
            }
            Text("moves")
                .font(.callout)
        }
        .foregroundStyle(Color.blue)
    }
    
    @ViewBuilder private func puzzleHintToogleView() -> some View {
        VStack{
            Button(action: {
                withAnimation{
                    showHint.toggle()
                }
            }, label: {
                Image(systemName: showHint ? "eye.circle.fill" : "eye.slash.circle.fill")
            })
            Text("Hint")
                .font(.callout)
        }
        .foregroundStyle(Color.green)
    }
    
    @ViewBuilder private func changePhotoView() -> some View {
        VStack {
            PhotoPickerView()
            Text("change")
                .font(.callout)
        }
        .foregroundStyle(Color.yellow)
    }
    private func reset(){
        moves = 0
        userWon = false
        loadedPuzzle = false
        puzzleImage = nil
        orderedTiles = nil
        shuffledTiles = nil
    }
}
extension ContentView {
    enum Direction {
        case up, down, left, right
    }
    
    private func tappedTile(row: Int, column: Int){
        guard userWon == false else {return}
        guard var shuffledTiles = shuffledTiles else {return}
        
        guard shuffledTiles[row][column].isSpareTile == false else {return}
        
        if let spareTileIndex = findAdjacentSpareTile(to: (row, column)){
            moves += 1
            let tappedTile = shuffledTiles[row][column]
            shuffledTiles[row][column] = shuffledTiles[spareTileIndex.0][spareTileIndex.1]
            shuffledTiles[spareTileIndex.0][spareTileIndex.1] = tappedTile
            
            self.shuffledTiles = shuffledTiles
            userWon = self.shuffledTiles == orderedTiles
        }
    }
    
    private func findAdjacentSpareTile(to tileIndex: (Int, Int)) -> (Int, Int)? {
        let directions: [Direction] = [.up,.down,.left,.right]
        
        for direction in directions {
            let adjacentTileIndex = getAdjacentTileIndex(from: tileIndex, direction: direction)
            if isValidIndex(adjacentTileIndex), shuffledTiles?[adjacentTileIndex.0][adjacentTileIndex.1].isSpareTile ?? false {
                return adjacentTileIndex
            }
        }
        
        return nil
    }
    
    private func getAdjacentTileIndex(from tileIndex: (Int, Int), direction: Direction) -> (Int, Int) {
        switch direction {
        case .up:
            return(tileIndex.0 - 1, tileIndex.1)
        case .down:
            return(tileIndex.0 + 1, tileIndex.1)
        case .left:
            return(tileIndex.0, tileIndex.1 - 1)
        case .right:
            return(tileIndex.0, tileIndex.1 + 1)
        }
    }
    
    private func isValidIndex(_ tileIndex: (Int, Int)) -> Bool {
        guard let shuffledTiles = shuffledTiles else {return false}
        return tileIndex.0 >= 0 && tileIndex.0 < shuffledTiles.count &&
        tileIndex.1 >= 0 && tileIndex.1 < shuffledTiles[tileIndex.0].count
    }
}

extension View {
    public func foregroundLinearGradient(colors: [Color], startPoint: UnitPoint, endPoint: UnitPoint) -> some View{
        self.overlay {
            LinearGradient(colors: colors, startPoint: startPoint, endPoint: endPoint)
                .mask(self)
        }
    }
}


#Preview {
    ContentView()
}
