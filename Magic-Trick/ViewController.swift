//
//  ViewController.swift
//  Magic-Trick
//
//  Created by Herrmann, Pascal H. (415) on 20.12.17.
//  Copyright © 2017 Herrmann, Pascal H. (415). All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    var magicSound: SCNAudioSource!
    
    var magicEnabled = false
    
    var hatNode: SCNNode?
    
    var balls: [SCNNode] = []
    
    var ballColors = [UIColor.red, UIColor.blue, UIColor.yellow, UIColor.green, UIColor.orange, UIColor.purple, UIColor.white]

    var placedHat = false

    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var tossButton: UIButton!
    @IBOutlet var sceneView: ARSCNView!
    
    func switchGui(ready: Bool){
        tossButton.isHidden = !ready
        infoLabel.isHidden = ready
    }
    
    func prepareGui(){
        infoLabel.lineBreakMode = .byWordWrapping
        infoLabel.numberOfLines = 0
        infoLabel.text = "Move your phone to find a surface. Tap it, to place the magic hat!"
        infoLabel.textColor = UIColor.blue
        infoLabel.backgroundColor = UIColor.init(red: 1, green: 1, blue: 1, alpha: 0.5)
        infoLabel.layer.borderColor = UIColor.blue.cgColor
        infoLabel.layer.cornerRadius = 8
        infoLabel.layer.borderWidth = 2
        infoLabel.layer.masksToBounds = true
        
        tossButton.layer.cornerRadius = 8
        tossButton.layer.borderWidth = 2
        tossButton.layer.borderColor = UIColor.blue.cgColor
        tossButton.setTitleColor(UIColor.blue, for: .normal)
        tossButton.backgroundColor = UIColor.init(red: 1, green: 1, blue: 1, alpha: 0.5)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        prepareGui()
        switchGui(ready: false)
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        //sceneView.showsStatistics = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
        sceneView.addGestureRecognizer(tap)
    
        // Create a new scene
        let scene = SCNScene.init() //SCNScene(named: "art.scnassets/empty.scn")!
        
        // Set the scene to the view
        sceneView.scene = scene
        
        magicSound = SCNAudioSource(fileNamed: "art.scnassets/TreasureOpen.mp3")
        magicSound.load()
    }
    
    @IBAction func didTapToss(_ sender: Any) {
        
        let ball = SCNSphere.init(radius: 0.05)
        
        let randomIndex = Int(arc4random_uniform(UInt32(ballColors.count)))
        ball.firstMaterial?.diffuse.contents = ballColors[randomIndex]
        
        let boxNode = SCNNode(geometry: ball)
        
        let camera = sceneView.session.currentFrame?.camera
        
        let cameraTransform = camera?.transform
        boxNode.simdTransform = cameraTransform!
        
        // Add box node to root node
        sceneView.scene.rootNode.addChildNode(boxNode)
        balls.append(boxNode)
        
        let forceDirection = SCNVector3Make(boxNode.worldFront.x*4, 1.5, boxNode.worldFront.z*4 )
        let physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        physicsBody.applyForce(forceDirection, asImpulse: true)
        boxNode.physicsBody = physicsBody
        
    }
    

    
    @objc func didTap(_ sender: UITapGestureRecognizer) {
        // Get tap location
        let tapLocation = sender.location(in: sceneView)
        
        if (!placedHat){
        
            // Perform hit test
            let results = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
            
            // If a hit was received, get position of
            if let result = results.first {
               placeHat(result)
            }
            
        } else {
            
            let hitResults = sceneView.hitTest(tapLocation, options: [SCNHitTestOption.rootNode:hatNode])
            if let _ = hitResults.first {
                //playMagicSound(toNode: result.node)
                
                let sparkles = SCNParticleSystem.init(named: "sparkles", inDirectory: nil)!
                hatNode?.addParticleSystem(sparkles)
                
                magicEnabled = !magicEnabled
                
                SCNTransaction.begin()

                for b in self.balls {
                                        
                    if (isInHat(ball:b)) {
                        b.opacity = (magicEnabled ? 0 : 1)
                    }
                }
                
                SCNTransaction.animationDuration = 2
                SCNTransaction.commit()
                
                hatNode?.runAction(SCNAction.playAudio(magicSound, waitForCompletion: true)) {
                    sparkles.birthRate = 0
                    //self.hatNode?.removeParticleSystem(sparkles)
                }

            }
            
        }
            
    }
    
    private func playMagicSound(toNode node: SCNNode) {
        node.runAction(SCNAction.playAudio(magicSound, waitForCompletion: false))
    }
    
    private func placeHat(_ result: ARHitTestResult) {
        
        // Get transform of result
        let transform = result.worldTransform
        
        // Get position from transform (4th column of transformation matrix)
        let planePosition = SCNVector3Make(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
        
        // Add door
        
        let hatScene = createHatFromScene(planePosition)!
        hatScene.opacity = 0
        sceneView.scene.rootNode.addChildNode(hatScene)
        
        SCNTransaction.begin()
        hatScene.opacity = 1
        SCNTransaction.animationDuration = 2
        SCNTransaction.commit()
        
        self.hatNode = hatScene.childNode(withName: "hat", recursively: true)
        switchGui(ready: true)
        
        placedHat = true
        planeNode?.removeFromParentNode()
    }
    
    private func createHatFromScene(_ position: SCNVector3) -> SCNNode? {
        guard let url = Bundle.main.url(forResource: "art.scnassets/magic-hat", withExtension: "scn") else {
            NSLog("Could not find door scene")
            return nil
        }
        guard let node = SCNReferenceNode(url: url) else { return nil }
        
        node.load()
        
        // Position scene
        node.position = position
        
        return node
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration: ARConfiguration
        
        // Check  number of degrees of freedom available on  device
        if ARWorldTrackingConfiguration.isSupported {
            configuration = ARWorldTrackingConfiguration()
            (configuration as! ARWorldTrackingConfiguration).planeDetection = .horizontal
        } else {
            configuration = AROrientationTrackingConfiguration()
        }

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    // MARK: - ARSCNViewDelegate
    
    private var planeNode: SCNNode?
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        // Create an SCNNode for a detect ARPlaneAnchor
        guard let _ = anchor as? ARPlaneAnchor else {
            return nil
        }
        planeNode = SCNNode()
        return planeNode
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // Create an SNCPlane on the ARPlane
        guard let planeAnchor = anchor as? ARPlaneAnchor else {
            return
        }
        
        if (placedHat){
            return
        }
        
        let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        
        let planeMaterial = SCNMaterial()
        planeMaterial.diffuse.contents = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.3)
        plane.materials = [planeMaterial]
        
        let planeNode = SCNNode(geometry: plane)
        planeNode.position = SCNVector3Make(planeAnchor.center.x, 0, planeAnchor.center.z)
        
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)
        
        node.addChildNode(planeNode)
    }
    
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
    }
    
    func isInHat(ball: SCNNode) -> Bool {
        let ballPosition = ball.presentation.worldPosition
        let hatBody = hatNode?.childNode(withName: "main", recursively: true)
        var (hatBoundingBoxMin, hatBoundingBoxMax) = (hatBody?.presentation.boundingBox)!
        let size = hatBoundingBoxMax - hatBoundingBoxMin
        
        hatBoundingBoxMin = SCNVector3((hatBody?.presentation.worldPosition.x)! - size.x/2,
                                       (hatBody?.presentation.worldPosition.y)!,
                                       (hatBody?.presentation.worldPosition.z)! - size.z/2)
        hatBoundingBoxMax = SCNVector3((hatBody?.presentation.worldPosition.x)! + size.x,
                                       (hatBody?.presentation.worldPosition.y)! + size.y,
                                       (hatBody?.presentation.worldPosition.z)! + size.z)
        
        return  ballPosition.x >= hatBoundingBoxMin.x  &&
                ballPosition.z >= hatBoundingBoxMin.z  &&
                ballPosition.x < hatBoundingBoxMax.x  &&
                ballPosition.y < hatBoundingBoxMax.y  &&
                ballPosition.z < hatBoundingBoxMax.z
    
    }
}
