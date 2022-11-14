//
//  CDVNfcReaderPlugin.swift
//
//  Created by Asial Corporation.
//  Copyright (c) 2022 Asial Corporation. All rights reserved.
//

import Foundation
import CoreNFC

// error message
let UNKNOWN_ERROR = "Unknown Error"
let INVALID_ARGUMENTS = "Invalid Arguments"
let NFC_NOT_AVAILABLE = "NFC Not Available"
let NFC_CONNECTION_ERROR = "NFC Connection Error"
let FEATURE_NOT_SUPPORTED_ERROR = "Feature Not Supported"
let TAG_NOT_SUPPORTED_ERROR = "Unsupported NFC Tag is detected"
let REQUEST_SERVICE_ERROR = "Request Service Error"
let READ_BLOCKDATA_ERROR = "Read Block Data Error"
let READ_BLOCKDATA_INVALID_STATUS_CODE = "Read Block Data Error: Invalid Status Code"
let NFC_READER_TIMEOUT = "NFC Session timed out"
let NFC_UNHANDLED_ERROR = "Unhandled NFC error"

// default message
let DEFAULT_NFC_SCAN_MESSAGE = "Bring the NFC tag closer to your Smartphone"

@available(iOS 13.0, *)
/// NFC Reader Plugin class
@objc(CDVNfcReaderPlugin) class CDVNfcReaderPlugin: CDVPlugin,
NFCNDEFReaderSessionDelegate,
NFCTagReaderSessionDelegate
{
    enum CommandType {
        case readId
        case readBlockData
    }
    
    var callbackId: String?
    var session: NFCTagReaderSession?
    var commandType: CommandType?
    var options: Dictionary<String, Any> = [:]

    @objc(readId:)
    /// Read ID of NFC Tags
    /// - Parameter command: inherited
    func readId(command: CDVInvokedUrlCommand) {
        self.callbackId = command.callbackId
        self.commandType = .readId
        self.options = (command.arguments[0] as? Dictionary<String, Any>)!
        self.startNFC()
    }

    @objc(readBlockData:)
    /// Read block data of FeliCa
    /// - Parameter command: inherited
    func readBlockData(command: CDVInvokedUrlCommand) {
        self.callbackId = command.callbackId
        self.commandType = .readBlockData
        self.options = (command.arguments[0] as? Dictionary<String, Any>)!
        guard let serviceCode = self.options["service_code"] as? [UInt8], serviceCode.count == 2 else {
            // error
            sendPluginResultWithError(error: INVALID_ARGUMENTS)
            return
        }
        guard let start = self.options["start"] as? Int, start >= 0 else {
            // error
            sendPluginResultWithError(error: INVALID_ARGUMENTS)
            return
        }
        guard let count = self.options["count"] as? Int, count <= 12, start + count <= 20 else {
            sendPluginResultWithError(error: INVALID_ARGUMENTS)
            return
        }
        self.startNFC()
    }
    
    /// Return values from plugin
    /// - Parameter result: result values
    func sendPluginResultWithValue(result: Dictionary<String, Any>) {
        let pluginResult: CDVPluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: result)
        self.commandDelegate.send(pluginResult, callbackId: self.callbackId)
    }
    
    /// Return error from plugin
    /// - Parameter error: error message
    func sendPluginResultWithError(error: String) {
        let pluginResult: CDVPluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: error)
        self.commandDelegate.send(pluginResult, callbackId: self.callbackId)
        
        self.session = nil
    }
    
    /// Start NFC session
    func startNFC() {
        if NFCTagReaderSession.readingAvailable {
            session = NFCTagReaderSession(pollingOption: [.iso18092, .iso14443], delegate: self)
            session?.alertMessage = (!self.options.isEmpty && self.options.keys.contains("message")) ? self.options["message"] as! String : DEFAULT_NFC_SCAN_MESSAGE
            session?.begin()
        } else {
            print("NFC is not available.")
            self.sendPluginResultWithError(error: NFC_NOT_AVAILABLE)
        }
    }
    
// MARK: NFCTagReaderSessionDelegate
    
    @available(iOS 13.0, *)
    /// override
    /// - Parameter session: inherited
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
    }
    
    @available(iOS 13.0, *)
    /// override
    /// - Parameters:
    ///   - session: inherited
    ///   - tags: inherited
    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        let tag = tags.first!
        session.connect(to: tag) { [self] (error) in
            if nil != error {
//                print("Error: ", error)
                self.sendPluginResultWithError(error: NFC_CONNECTION_ERROR)
                return
            }
            if case let .feliCa(feliCaTag) = tag {
                switch self.commandType {
                case .readId:
                    self.readFelicaTagId(session, feliCaTag: feliCaTag)
                    break
                case .readBlockData:
                    self.readFelicaBlockData(session, feliCaTag: feliCaTag)
                    break
                default:
                    break
                }
            } else if case let .miFare(miFareTag) = tag {
                switch self.commandType {
                case .readId:
                    self.readMiFareTagId(session, miFareTag: miFareTag)
                    break
                case .readBlockData:
                    // not supported
                    self.sendPluginResultWithError(error: FEATURE_NOT_SUPPORTED_ERROR)
                    session.invalidate()
                    return
                default:
                    break
                }
            } else {
                print("Detected NFC tag is not supported.")
                sendPluginResultWithError(error: TAG_NOT_SUPPORTED_ERROR)
                session.invalidate()
                return
            }
        }
    }
    
    @available(iOS 13.0, *)
    /// override
    /// - Parameters:
    ///   - session: inherited
    ///   - error: inherited
    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        if self.session == nil {
            // called after session invalidated, but it's not necessary to return error
            return
        }
        print("error:\(error.localizedDescription)")
        switch error {
        case NFCReaderError.readerSessionInvalidationErrorUserCanceled:
            let result: Dictionary<String, Any> = ["id": "", "type": "", "cancelled": true]
            self.sendPluginResultWithValue(result: result)
            break
        case NFCReaderError.readerSessionInvalidationErrorSessionTimeout:
            self.sendPluginResultWithError(error: NFC_READER_TIMEOUT)
            break
        default:
            self.sendPluginResultWithError(error: NFC_UNHANDLED_ERROR)
            break
        }
    }
    
    /// Read ID of NFC Type A tag
    /// - Parameters:
    ///   - session: NFC session
    ///   - miFareTag: Tag
    func readMiFareTagId(_ session: NFCTagReaderSession, miFareTag: NFCMiFareTag) {
        let id = miFareTag.identifier.map { String(format: "%.2hhx", $0) }.joined()
        print("UID: \(id)")
        
        session.invalidate()
        
        let result: Dictionary<String, Any> = ["id": id, "type": "typeA", "cancelled": false]
        self.sendPluginResultWithValue(result: result)
    }
    
    /// Read ID of NFC Type F tag
    /// - Parameters:
    ///   - session: NFC session
    ///   - feliCaTag: Tag
    func readFelicaTagId(_ session: NFCTagReaderSession, feliCaTag: NFCFeliCaTag) {
        let id = feliCaTag.currentIDm.map { String(format: "%.2hhx", $0) }.joined()
        print("IDm: \(id)")
        
        session.invalidate()
        
        let result: Dictionary<String, Any> = ["id": id, "type": "typeF", "cancelled": false]
        self.sendPluginResultWithValue(result: result)
    }
    
    /// Read block data of NFC Type F tag
    /// - Parameters:
    ///   - session: NFC session
    ///   - feliCaTag: Tag
    func readFelicaBlockData(_ session: NFCTagReaderSession, feliCaTag: NFCFeliCaTag) {
        
        let id = feliCaTag.currentIDm.map { String(format: "%.2hhx", $0) }.joined()

        let serviceCode = Data((self.options["service_code"] as! [UInt8]).reversed())
        feliCaTag.requestService(nodeCodeList: [serviceCode]) { nodes, error in
            if let error = error {
                print("Error:", error)
                self.sendPluginResultWithError(error: REQUEST_SERVICE_ERROR)
                session.invalidate()
                return
            }

            guard let data = nodes.first, data != Data([0xff, 0xff]) else {
                print("History data is not found.")
                self.sendPluginResultWithError(error: REQUEST_SERVICE_ERROR)
                session.invalidate()
                return
            }
        }

        let start: Int = self.options["start"] as! Int
        let count: Int = self.options["count"] as! Int
        let block:[Data] = (start..<(start + count)).map { Data([0x80, UInt8($0)]) }
        feliCaTag.readWithoutEncryption(serviceCodeList: [serviceCode], blockList: block) {status1, status2, dataList, error in
                
            if let error = error {
                print("Error: ", error)
                self.sendPluginResultWithError(error: READ_BLOCKDATA_ERROR)
                session.invalidate()
                return
            }
            guard status1 == 0x00, status2 == 0x00 else {
                print("Status code is invalid: ", status1, " / ", status2)
                self.sendPluginResultWithError(error: READ_BLOCKDATA_INVALID_STATUS_CODE)
                session.invalidate()
                return
            }
            session.invalidate()
            self.session = nil
            
            let byteArray = dataList.map { $0.map { Int($0)} }
            let result: Dictionary<String, Any> = ["id": id, "type": "typeF", "cancelled": false, "data": byteArray]
            self.sendPluginResultWithValue(result: result)
        }

    }
    
    // MARK: NFCNDEFReaderSessionDelegate

    /// override
    /// - Parameter session: inherited
    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {

    }
    
    /// override
    /// - Parameters:
    ///   - session: inherited
    ///   - error: inherited
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        print("error:\(error.localizedDescription)")
    }
    
    /// override
    /// - Parameters:
    ///   - session: inherited
    ///   - messages: inherited
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {

        for message in messages {
            for record in message.records {
                print(String(data: record.payload, encoding: .utf8)!)
            }
        }
    }

}
