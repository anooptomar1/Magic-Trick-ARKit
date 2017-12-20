//
//  SCN3Vector.swift
//  Magic-Trick
//
//  Created by Herrmann, Pascal H. (415) on 20.12.17.
//  Copyright © 2017 Herrmann, Pascal H. (415). All rights reserved.
//

import ARKit

extension SCNVector3{
    
    static func + (left: SCNVector3, right : SCNVector3) -> SCNVector3 {
        return SCNVector3(left.x + right.x, left.y + right.y, left.z + right.z)
    }
    
    static func - (left: SCNVector3, right : SCNVector3) -> SCNVector3 {
        return SCNVector3(left.x - right.x, left.y - right.y, left.z - right.z)
    }
    
    static func / (left: SCNVector3, right : Float) -> SCNVector3 {
        return SCNVector3(left.x / right, left.y / right, left.z / right)
    }
    
    static func * (left: SCNVector3, right : Float) -> SCNVector3 {
        return SCNVector3(left.x * right, left.y * right, left.z * right)
    }
    
}
