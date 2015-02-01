//
//  client.swift
//  cap
//

//  Copyright (c) 2015 na. All rights reserved.
//
import Starscream
import SwiftyJSON

import Foundation
import CoreLocation

private let _SingletonASharedInstance = Client()


let serverUrl = "192.168.1.60:8000"

class Client: NSObject, WebSocketDelegate{
    class var sharedInstance : Client {
        return _SingletonASharedInstance
    }
    
   
    var view: AnyObject? = nil
    var socket = WebSocket(url: NSURL(scheme: "ws", host: serverUrl, path: "/device")!)
    var img: String = ""
    var connected: Bool = false
    
    override init() {
        super.init()
    }
    
    
    func connect() {
        socket.delegate = self
        socket.connect()
    }
    
    func uploadImg(var data: String, var skill: String) {
        var json: JSON = ["cmd": "uploadImg", "data":data]
        socket.writeData(json.rawData()!)
            
        img = data
    }
    
  
    //got message call back
    func gotMessage(from: String, msg: String) {
        println("got message \(from) \(msg)")
        
        var viewController = self.view as ViewController
    }
  
    func websocketDidConnect(socket: Starscream.WebSocket) {
        println("connected")
        
        var json:JSON = ["cmd":"login", "name": "a iphone"]
        socket.writeData(json.rawData()!)
        
    }
    
    func websocketDidDisconnect(socket: Starscream.WebSocket, error: NSError?) {
        println("disconnect")
        
        self.socket.connect()
    }
    
    func websocketDidReceiveMessage(socket: Starscream.WebSocket, text: String) {
        println("Received text: \(text)")
        var json:JSON = JSON(data: text.dataUsingEncoding(NSUTF8StringEncoding)!)
        
        switch json["cmd"].stringValue {
        case "requestImg":
            var view = self.view as ViewController
            view.captureImage(0)            
        default:
            print("n/a")
            
        }
    }
    
    func websocketDidReceiveData(socket: Starscream.WebSocket, data: NSData) {
        println("Received data: \(data.length)")
    }
}