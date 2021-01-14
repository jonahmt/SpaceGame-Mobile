//
//  GameScene.swift
//  SpaceGame
//
//  Created by Mobile on 12/2/20.
//  Copyright © 2020 Mobile. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var player:SKSpriteNode!
    var scoreLabel:SKLabelNode!
    
    var score:Int = 0
    
    var laserFireRate:TimeInterval = 0.4
    var timeSinceLaserFired:TimeInterval = 0.0
    
    var enemySpawnRate:TimeInterval = 0.65
    var timeSinceEnemySpawned:TimeInterval = 0.0
    var maxEnemySideSpeed = 75
    
    var powerUpSpawnRate:TimeInterval = 7.5
    var timeSincePowerUpSpawned = 3.0
    
    var lastUpdateTime:TimeInterval = 0.0
    
    // Pre load the laser sound
    let laserSoundAction:SKAction = SKAction.playSoundFileNamed("laser", waitForCompletion: false)
    
    // Bitmask setup
    let noCategory:UInt32 = 0
    let laserCategory:UInt32 = 1   // ....00001
    let playerCategory:UInt32 = 2  // ....00010
    let enemyCategory:UInt32 = 4   // ....00100
    let powerUpCategory:UInt32 = 8 // ....01000
    
    // Note: bitwise or "|" ors each bit of two numbers together, and that is the resulting number. ex) 00001 | 00100 = 00101
    
    
    override func didMove(to view: SKView) {
        // Tell iOS which clas will implement the SKPhysicsContactDelegate methods
        self.physicsWorld.contactDelegate = self
        
        // Prepopulate the stars:
        let largeStarEmitter = (self.childNode(withName: "largeStarEmitter") as! SKEmitterNode)
        largeStarEmitter.advanceSimulationTime(40.0)
        let smallStarEmitter = (self.childNode(withName: "smallStarEmitter") as! SKEmitterNode)
        smallStarEmitter.advanceSimulationTime(40.0)

        
        player = (self.childNode(withName: "player1") as! SKSpriteNode)
        player.physicsBody?.categoryBitMask = playerCategory
        player.physicsBody?.contactTestBitMask = enemyCategory | powerUpCategory
        player.physicsBody?.collisionBitMask = noCategory
        
        scoreLabel = (self.childNode(withName: "scoreLabel") as! SKLabelNode)
        scoreLabel.text = String(score)
        
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        // Code to handle when physics bodies contact each other
        let categoryA = contact.bodyA.categoryBitMask
        let categoryB = contact.bodyB.categoryBitMask
        
        // First check that we haven't already removed one or both of these nodes as a result of a prior call to this function
        if contact.bodyA.node?.parent == nil || contact.bodyB.node?.parent == nil {
            return
        }
        
        // Handle the case where the player is involved:
        if categoryA == playerCategory || categoryB == playerCategory {
            // 1) Figure out which body is the player
            let notThePlayer:SKNode = (categoryA == playerCategory) ? contact.bodyB.node! : contact.bodyA.node!
            // 2) Figure out what to do in another method
            playerDidContact(with: notThePlayer)
        } else { // Handle the case where the player isn't involved (laser and enemy):
            // Run the explosion particle emitter
            if let explosion = SKEmitterNode(fileNamed: "Explosion") {
                self.addChild(explosion)
                explosion.setScale(0.5)
                explosion.position = contact.bodyA.node!.position
                
                // Run it, then delete it after a second or two
                let waitAction = SKAction.wait(forDuration: 2.0)
                let removeAction = SKAction.removeFromParent()
                let actionSequence = SKAction.sequence([waitAction, removeAction])
                explosion.run(actionSequence)
                
                // Run the laser sound
                self.run(laserSoundAction)
            }
            // FUTURE NOTE: give ourselves a point and delete the enemy
            contact.bodyA.node?.removeFromParent()
            contact.bodyB.node?.removeFromParent()
                        
            // Add to score
            addToScore(by: 1)

        }
        
    }
    
    func playerDidContact(with otherNode: SKNode) {
        // Was otherNode an enemy? If so - we are going to
        if otherNode.physicsBody?.categoryBitMask == enemyCategory {
            // 1) Remove both
            otherNode.removeFromParent()
            player.removeFromParent()
            // 2) Stop the lasers from spawning
            laserFireRate = .infinity
            // 3) Transition to an end screen
            
            if let scene = SKScene(fileNamed: "StartScene") as? StartScene {
                scene.scaleMode = .aspectFill
                view!.presentScene(scene, transition: .doorsCloseHorizontal(withDuration: 2.0))
            }
        
        } else if otherNode.physicsBody?.categoryBitMask == powerUpCategory {
        // or a powerUp?
            // 1) Remove the powerUp
            otherNode.removeFromParent()
            // 2) Give some effect or points
            addToScore(by: 5)
        }
    }
    
    func addToScore(by amount: Int) {
        score += amount
        enemySpawnRate = 0.65 * pow(1.058, Double(-score)/10)
        // Update text
        scoreLabel.text = String(score)
        if score >= 250 {
            scoreLabel.fontColor = .red
        }
        // Update maxEnemySideSpeed
        if score >= 175 {
            maxEnemySideSpeed = 125
        }
        if score >= 280 {
            maxEnemySideSpeed = 200
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        for t in touches {
            let loc = t.location(in: self)
            player.position = loc
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            let loc = t.location(in: self)
            player.position = loc
        }
    }
    
    func spawnLaser() {
        // Check that we have a scene file called Laser
        if let laserScene = SKScene(fileNamed: "Laser") {
            // Check that the scene file has a sprite called laser
            if let laser = laserScene.childNode(withName: "laser") {
                // Copy that laser sprite to this scene, at the location of the player ship
                laser.move(toParent: self) // copy operation
                laser.position = player.position
                laser.physicsBody?.categoryBitMask = laserCategory
                // When this object touches an enemy, didBegin is called
                laser.physicsBody?.contactTestBitMask = enemyCategory
                laser.physicsBody?.collisionBitMask = noCategory

            }
        }
    }
    
    func spawnEnemy() {
        if let enemyScene = SKScene(fileNamed: "Enemy") {
            if let enemy = enemyScene.childNode(withName: "enemy") {
                enemy.move(toParent: self)
                enemy.position = CGPoint(x: Int.random(in: Int(-self.size.width/2 + 10)...Int(self.size.width/2 - 10)), y: Int(self.size.height/2))
                
                // Set enemy speed
                var speed = Int.random(in: -325 * (1 + score/175) ... -300)
                // If the enmy is randomy chosen or the score is high, make it very fast
                if score >= 60 && Int.random(in: 1 ... 10) == 7 - Int(score/125)  || score >= 250 {
                    speed = -500 - score * 2
                }
                enemy.physicsBody?.velocity.dy = CGFloat(speed)
                
                // If the enemy is randomy chosen, give it some x velocity
                let sideSpeed = Int.random(in: -maxEnemySideSpeed ... maxEnemySideSpeed)
                if Int.random(in: 1 ... 10) >= 7 {
                    enemy.physicsBody?.velocity.dx = CGFloat(sideSpeed)
                }
                
                enemy.physicsBody?.categoryBitMask = enemyCategory
                // When this object touches a laser or the player, did begin is called
                enemy.physicsBody?.contactTestBitMask = laserCategory | playerCategory
                enemy.physicsBody?.collisionBitMask = noCategory

                // Allow for animation:
                enemy.isPaused = false
            }
        }
    }
    
    func spawnPowerUp() {
        if let powerUpScene = SKScene(fileNamed: "PowerUp") {
            if let powerUp = powerUpScene.childNode(withName: "powerUp") {
                
                let leftSide:Bool = Bool.random()
                
                powerUp.move(toParent: self)
                if leftSide {
                    powerUp.position = CGPoint(x: Int(-self.size.width/2), y: Int.random(in: 25...Int(self.size.height/2 - 10)))
                    powerUp.physicsBody?.velocity = CGVector(dx: 600, dy: 0)
                } else {
                    // right side
                    powerUp.position = CGPoint(x: Int(self.size.width/2), y: Int.random(in: 25...Int(self.size.height/2 - 10)))
                }
                powerUp.physicsBody?.categoryBitMask = powerUpCategory
                    // When this object touches the player, did begin is called.
                powerUp.physicsBody?.contactTestBitMask = playerCategory
                powerUp.physicsBody?.collisionBitMask = noCategory
            }
        }
    }
    
    func checkLaser(_ updateDelta:TimeInterval) {
        // Check if laserFireRate time has passed
        // If so, call Spawn Laser
        if timeSinceLaserFired >=  laserFireRate {
            spawnLaser()
            timeSinceLaserFired = 0.0
        } else {
            // Add the te since update was last called
            timeSinceLaserFired += updateDelta
        }
    }
    
    func checkEnemy(_ updateDelta:TimeInterval) {
        if timeSinceEnemySpawned >= enemySpawnRate {
            spawnEnemy()
            timeSinceEnemySpawned = 0.0
        } else {
            timeSinceEnemySpawned += updateDelta
        }
    }
    
    func checkPowerUp(_ updateDelta:TimeInterval) {
        if timeSincePowerUpSpawned >= powerUpSpawnRate {
            spawnPowerUp()
            timeSincePowerUpSpawned = 0.0
            // Randomize time between powerUp spawns
            powerUpSpawnRate = Double.random(in: 1.0 ... 10.0)
        } else {
            timeSincePowerUpSpawned += updateDelta
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        self.checkLaser(currentTime - lastUpdateTime)
        self.checkEnemy(currentTime - lastUpdateTime)
        self.checkPowerUp(currentTime - lastUpdateTime)
        
        lastUpdateTime = currentTime
        
        // Remove sprites that have gone offscreen
        for childNode in self.children {
            // Just deal with sprite nodes so we don't remove anything we don't want to
            if let child = childNode as? SKSpriteNode {
                // Check if the node is offscren, and remove it if so
                if !child.intersects(self) {
                    child.removeFromParent()
                }
            }
        }
    }
}
