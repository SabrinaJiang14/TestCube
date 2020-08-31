//
//  ViewController.swift
//  TestCube
//
//  Created by sabrina on 2020/8/26.
//  Copyright © 2020 sabrina. All rights reserved.
//

import UIKit
import CoreMotion

class ViewController: UIViewController, UICollisionBehaviorDelegate, UIDynamicAnimatorDelegate {
    
    @IBOutlet weak var btnBegin: UIButton!
    @IBOutlet weak var diceView: UIImageView!

    let aDegree = CGFloat.pi / 180
    var angle = CGPoint(x: 0, y: 0)

    var dynamicAnimator = UIDynamicAnimator()
    
    var images:[CubeImage] = []
    let totalCount = 4
    let manager = CMMotionManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initCubeLayer()
        initCube()
    }
    
    func initCubeLayer() {
        dynamicAnimator = UIDynamicAnimator(referenceView: diceView)
        let path = UIBezierPath(arcCenter: CGPoint(x: diceView.bounds.midX, y: 150), radius: diceView.bounds.width/2, startAngle: aDegree*0, endAngle: 180*aDegree, clockwise: false)
        path.addLine(to: CGPoint(x: 0, y: diceView.bounds.maxY))
        path.addLine(to: CGPoint(x: diceView.bounds.maxX, y: diceView.bounds.maxY))
        path.close()
        let layer = CAShapeLayer()
        layer.path = path.cgPath
        diceView.layer.mask = layer
    }
    
    func initCube() {
        dynamicAnimator.removeAllBehaviors()
        images.removeAll()
        self.diceView.subviews.forEach { (img) in
            img.removeFromSuperview()
        }
        (0..<totalCount).forEach { (index) in
            let img = CubeImage(frame: CGRect(x: 50*index+50, y: Int(diceView.bounds.maxY-60), width: 45, height: 45))
            img.image = UIImage(named: "dong\(index+1)")
            self.images.append(img)
            self.diceView.addSubview(img)
        }
    }
    
    func addDynamicAnimator(point:CGPoint) {
        
         //重力行為
        let gravite = UIGravityBehavior(items: images)
        
        // 创建弧形路径对象
        let path = UIBezierPath(arcCenter: CGPoint(x: diceView.bounds.midX, y: 150), radius: diceView.bounds.width/2, startAngle: aDegree*0, endAngle: 180*aDegree, clockwise: false)
        path.addLine(to: CGPoint(x: 5, y: diceView.bounds.maxY-15))
        path.addLine(to: CGPoint(x: diceView.bounds.maxX-5, y: diceView.bounds.maxY-15))
        path.close()
        
        //碰撞行為
        let collisionBehavior = UICollisionBehavior(items: images) //用參考視圖邊界作為碰撞邊界
        collisionBehavior.translatesReferenceBoundsIntoBoundary = true
        collisionBehavior.collisionMode = .everything
        collisionBehavior.collisionDelegate = self
        collisionBehavior.addBoundary(withIdentifier: "path1" as NSCopying, for: path)
        
        
        //物體屬性行為包括彈性、摩擦力、密度、阻力等等
        let litterBehavior = UIDynamicItemBehavior(items: images)
        litterBehavior.elasticity = 0.8 //彈性
        litterBehavior.density = 1 //密度
        litterBehavior.friction = 0.01 //摩擦
        litterBehavior.resistance = 0.05 //阻力
        litterBehavior.angularResistance = 0.2 //電阻
        
        let push1 = UIPushBehavior(items: [images[0], images[2]], mode: .instantaneous)
        push1.active = true
        push1.setAngle(pointToAngle(p: CGPoint(x: 50, y: -300)), magnitude: 10)
        
        let push2 = UIPushBehavior(items: [images[1], images[3]], mode: .instantaneous)
        push2.active = true
        push2.setAngle(pointToAngle(p: CGPoint(x: 150, y: -150)), magnitude: 5)
        
        dynamicAnimator.addBehavior(push1)
        dynamicAnimator.addBehavior(push2)
        dynamicAnimator.addBehavior(gravite)
        dynamicAnimator.addBehavior(collisionBehavior)
        dynamicAnimator.addBehavior(litterBehavior)
        dynamicAnimator.delegate = self
    }
    
    //根据给定点和view中心点计算角度
    func pointToAngle(p:CGPoint)->CGFloat{
        let o: CGPoint = CGPoint(x: self.view.bounds.midX, y: self.view.bounds.midY)
        let angle: CGFloat = atan2(p.y - o.y, p.x - o.x)
        return angle
    }
    
    @IBAction func tapCube(_ sender: UIButton) {
        initCube()
        let btnFrame = self.view.convert(btnBegin.frame, to: self.view.superview)
        addDynamicAnimator(point: btnFrame.origin)
    }
    
    func isAccelerometerAvailable() {
        if manager.isAccelerometerAvailable {
            manager.deviceMotionUpdateInterval = 1/60
            manager.startAccelerometerUpdates(to: OperationQueue.main) { (data, error) in
                guard let data = data else { return }
                self.images.first!.accelleration = data.acceleration
                DispatchQueue.main.async {
                    self.images.first!.updateLocation(boundaryItem: self.diceView)
                }
                
            }
        }
    }
    
    override func motionBegan(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            let btnFrame = self.view.convert(btnBegin.frame, to: self.view.superview)
            addDynamicAnimator(point: btnFrame.origin)
        }
    }
    
    //随机产生不同的号码
    func getRandomNumbers(_ count:Int,lenth:UInt32) -> [Int] {
        var randomNumbers = [Int]()
        for _ in 0...(count - 1) {
            var number = Int()
            number = Int(arc4random_uniform(lenth))+1
            while randomNumbers.contains(number) {
                number = Int(arc4random_uniform(lenth))+1
            }
            randomNumbers.append(number)
        }
        return randomNumbers
    }
    
    func collisionBehavior(_ behavior: UICollisionBehavior, endedContactFor item: UIDynamicItem, withBoundaryIdentifier identifier: NSCopying?) {
    }
    
    func collisionBehavior(_ behavior: UICollisionBehavior, beganContactFor item: UIDynamicItem, withBoundaryIdentifier identifier: NSCopying?, at p: CGPoint) {
    }
    
    func dynamicAnimatorWillResume(_ animator: UIDynamicAnimator) {
        if animator.isRunning {
            manager.stopAccelerometerUpdates()
        }
    }
    
    func dynamicAnimatorDidPause(_ animator: UIDynamicAnimator) {
        if !animator.isRunning {
            isAccelerometerAvailable()
        }
    }
}

class CubeImage:UIImageView {
    //图片的宽高
    var imageWidth : CGFloat = 45
    var imageHeight : CGFloat = 45
    var accelleration = CMAcceleration()
    var speedX:Double = 0
    var speedY:Double = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = UIColor.clear
    }
    
    func updateLocation(boundaryItem : UIView) {
        
        self.speedX += accelleration.x
        self.speedY += accelleration.y
        
        var posX:CGFloat = self.center.x + CGFloat(self.speedX)
        var posY:CGFloat = self.center.y - CGFloat(self.speedY)
        
        if posX < 40.0 {
            posX = 40.0
            self.speedX *= -0.5
        }else if (posX > boundaryItem.frame.size.width - 40) {
            posX = boundaryItem.frame.size.width - 40
            self.speedX *= -0.5
        }
        
        if posY < 40.0 {
            posY = 40.0
            self.speedY *= -0.5
        }else if (posY > (boundaryItem.frame.size.height - 40)) {
            posY = boundaryItem.frame.size.height - 40
            self.speedY *= -0.5
        }
        
        self.center = CGPoint(x: posX, y: posY)
    }
}
