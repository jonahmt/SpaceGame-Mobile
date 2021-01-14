//
//  StartScene.swift
//  SpaceGame
//
//  Created by Mobile on 12/16/20.
//  Copyright © 2020 Mobile. All rights reserved.
//

import Foundation
import SpriteKit

class StartScene: SKScene {
    
    override func didMove(to view: SKView) {
        // pass
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let scene = SKScene(fileNamed: "GameScene") {
            // Set the scale mode to scale to fit the window
            scene.scaleMode = .aspectFill
            
            // Present the scene
            view!.presentScene(scene, transition: .doorsOpenVertical(withDuration: 1.5))
        }
    }
    
}
