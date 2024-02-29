// FishViewModel.swift

import UIKit

class FishViewModel {
    private let fishModel: [Fish]

    init(fishModel: [Fish]) {
        self.fishModel = fishModel
    }

    func getRandomFish() -> Fish {
        let randomIndex = Int.random(in: 0..<fishModel.count)
        return fishModel[randomIndex]
    }

    func getFishModel() -> [Fish] {
        return fishModel
    }
}
