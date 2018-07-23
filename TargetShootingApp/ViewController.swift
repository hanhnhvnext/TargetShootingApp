//
//  ViewController.swift
//  TargetShootingApp
//
//  Created by Hanh Nguyen on 7/23/18.
//  Copyright © 2018 Hanh Nguyen. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

enum BodyType : Int {
    case bullet = 1
    case barrier = 2
}

class ViewController: UIViewController, ARSCNViewDelegate, SCNPhysicsContactDelegate {

    @IBOutlet var sceneView: ARSCNView!
    var lastContactNode : SCNNode!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.showsStatistics = true
        
        let scene = SCNScene()
        
        let boxGeometry = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
        let boxMaterial = SCNMaterial()
        boxMaterial.diffuse.contents = UIColor.red
        boxGeometry.materials = [boxMaterial]
        
        let box1Node = SCNNode(geometry: boxGeometry)
        let box2Node = SCNNode(geometry: boxGeometry)
        let box3Node = SCNNode(geometry: boxGeometry)
        
        box1Node.position = SCNVector3Make(0.0, 0.0, -1)
        box1Node.name = "barrier1"
        box1Node.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        box1Node.physicsBody?.categoryBitMask = BodyType.barrier.rawValue
        
        box2Node.position = SCNVector3Make(-0.2, 0.0, -1)
        box2Node.name = "barrier2"
        box2Node.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        box2Node.physicsBody?.categoryBitMask = BodyType.barrier.rawValue
        
        box3Node.position = SCNVector3Make(0.2, 0.0, -1)
        box3Node.name = "barrier3"
        box3Node.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        box3Node.physicsBody?.categoryBitMask = BodyType.barrier.rawValue
        
        scene.rootNode.addChildNode(box1Node)
        scene.rootNode.addChildNode(box2Node)
        scene.rootNode.addChildNode(box3Node)

        sceneView.scene = scene
        self.sceneView.scene.physicsWorld.contactDelegate = self
        registerGestureRecognizer()
    }
    
    func physicsWorld(_ world: SCNPhysicsWorld, didEnd contact: SCNPhysicsContact) {
        var contactNode : SCNNode!
        
        if contact.nodeA.name == "bullet" {
            contactNode = contact.nodeB
        } else {
            contactNode = contact.nodeA
        }
        
        if self.lastContactNode != nil && self.lastContactNode == contactNode { return }
        self.lastContactNode = contactNode
        
        //3 barrier deu refer den 1 geometry o tren, nen neu thay doi geometry cua 1 box thi ca 3 barrier deu thay doi.
        //do do phai init 1 box moi.
        let box = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
        
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.green
        box.materials = [material]
        
        self.lastContactNode.geometry = box
        
    }
    
    func registerGestureRecognizer(){
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(shoot))
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func shoot(recognizer: UIGestureRecognizer){
        guard let currentFrame = self.sceneView.session.currentFrame else { return }
        ///tao ra 1 matran chuyen doi voi x, y giu nguyen va dich chuyen z ra xa 0.3m
        var translation = matrix_identity_float4x4
        translation.columns.3.z = -0.3
        
        let boxGeometry = SCNBox(width: 0.05, height: 0.05, length: 0.05, chamferRadius: 0)
        let boxMaterial = SCNMaterial()
        boxMaterial.diffuse.contents = UIColor.yellow
        boxGeometry.materials = [boxMaterial]
        
        let boxNode = SCNNode(geometry: boxGeometry)
        boxNode.name = "bullet"
        boxNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        boxNode.physicsBody?.isAffectedByGravity = false
        boxNode.physicsBody?.categoryBitMask = BodyType.bullet.rawValue
        //khi xay ra va cham vs node barrier thi se trigger ham physicsWorld o tren
        boxNode.physicsBody?.contactTestBitMask = BodyType.barrier.rawValue
        
        //multiply 2 ma tran: 1 ma tran transform: huong va vi tri cua camera va 1 ma tran chuyen doi o tren: dua
        //z ra cach xa 0.3m so voi camera. Sau do ap dung matran ket qua nay de transfrom node moi ve: simdRotation,
        //simdOrientation, simdEulerAngle, simdPosition de tao ra hieu ung ban bullet tu camera - goc nhin cua player.
        boxNode.simdTransform = matrix_multiply(currentFrame.camera.transform, translation)
        let forceVector = SCNVector3Make(boxNode.worldFront.x * 2, boxNode.worldFront.y * 2, boxNode.worldFront.z * 2)
        boxNode.physicsBody?.applyForce(forceVector, asImpulse: true)
        sceneView.scene.rootNode.addChildNode(boxNode)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
  
        let configuration = ARWorldTrackingConfiguration()

        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
    }
    
}
