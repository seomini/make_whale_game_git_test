// GameViewModel.swift

import UIKit

class GameViewModel {
    private let fishViewModel: FishViewModel

    init(fishViewModel: FishViewModel) {
        self.fishViewModel = fishViewModel
    }
    func getNextRandomFish() -> Fish {
        return fishViewModel.getRandomFish()
    }
}
