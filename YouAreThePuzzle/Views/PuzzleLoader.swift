//
//  PuzzleLoader.swift
//  YouAreThePuzzle
//
//  Created by Heical Chandra on 31/05/24.
//

import Foundation
import PhotosUI
import SwiftUI

struct PuzzleLoader {
    func LoadPuzzleFromItem(_ photoItem: PhotosPickerItem) async throws -> (UIImage, ([[PuzzleTile]], [[PuzzleTile]])){
        guard let imageData = try await photoItem.loadTransferable(type: Data.self) else {
            throw NSError(domain: "Error load photo item from library", code: 0)
        }
        guard let inputImage = UIImage(data: imageData),
              let croppedImage = cropImageForPuzzle(image: inputImage) else {
            throw NSError(domain: "Error loading puzzle image", code: 1)
        }
        let tiles = tilesFromImage(image: croppedImage, size: CGSize(width: croppedImage.size.width/3, height: croppedImage.size.height/3))
        
        return (croppedImage, tiles)
    }
    //crop image to square
    private func cropImageForPuzzle(image: UIImage) -> UIImage?{
        let minLength = min(image.size.width, image.size.height)
        let x = image.size.width / 2 - minLength / 2
        let y = image.size.height / 2 - minLength / 2
        let croppingRect = CGRect(x: x, y: y, width: minLength, height: minLength)
        
        if let croppedCGIImage = image.cgImage?.cropping(to: croppingRect){
            return UIImage(cgImage: croppedCGIImage, scale: image.scale, orientation: image.imageOrientation)
        }
        return nil
    }
    private func tilesFromImage(image: UIImage, size: CGSize) -> ([[PuzzleTile]], [[PuzzleTile]]){
        let hRowCount = Int(image.size.width / size.width)
        let vRowCount = Int(image.size.width / size.height)
        let titleSideLength = size.width
        
        var tiles = [[PuzzleTile]](repeating: [], count: vRowCount)
        for vIndex in 0..<vRowCount {
            for hIndex in 0..<hRowCount {
                if vIndex == vRowCount - 1 && hIndex == hRowCount - 1 {
                    tiles[vIndex].append(PuzzleTile(image: nil, isSpareTile: true))
                } else {
                    let imagePoint = CGPoint(x: CGFloat(hIndex) * titleSideLength * -1, y: CGFloat(vIndex) * titleSideLength * -1)
                    UIGraphicsBeginImageContextWithOptions(size, false, 0)
                    image.draw(at: imagePoint)
                    
                    if let newImage = UIGraphicsGetImageFromCurrentImageContext(){
                        tiles[vIndex].append(PuzzleTile(image: newImage))
                    }
                    UIGraphicsEndImageContext()
                }
            }
        }
        var iterator = tiles.joined().shuffled().makeIterator()
        let shuffledTiles = tiles.map {$0.compactMap {_ in iterator.next()}}
        return (tiles, shuffledTiles)
    }
}
