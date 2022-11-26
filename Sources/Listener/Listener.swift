//
//  Listener.swift
//  
//
//  Created by Douglas Adams on 11/26/22.
//

import Foundation

import Shared

public class Listener {
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _lanListener: LanListener?
  private var _wanListener: WanListener?
  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  public func setConnectionMode(_ local: Bool, _ smartlink: Bool, _ smartlinkEmail: String = "") async -> Bool {
    if !local {
      _lanListener?.stop()
      _lanListener = nil
      PacketCollection.shared.removePackets(condition: { $0.source == .local } )
    }
    if !smartlink {
      _wanListener?.stop()
      _wanListener = nil
      PacketCollection.shared.removePackets(condition: { $0.source == .smartlink } )
    }

    switch (local, smartlink) {
      
    case (true, true):
      if _lanListener == nil {
        _lanListener = LanListener()
        _lanListener!.start()
      }
      if _wanListener == nil {
        _wanListener = WanListener()
        return await _wanListener!.start(smartlinkEmail)
      }
      return true
      
    case (true, false):
      if _lanListener == nil {
        _lanListener = LanListener()
        _lanListener!.start()
      }
      return true
      
    case (false, true):
      if _wanListener == nil {
        _wanListener = WanListener()
        return await _wanListener!.start(smartlinkEmail)
      }
      return true
      
    case (false, false):
      return true
    }
  }

  public func forceWanLogin() {
    _wanListener?.forceLogin()
  }
  
  /// Send a Test message
  /// - Parameter serial:     radio serial number
  /// - Returns:              success / failure
  public func sendWanTest(_ serial: String) {
    log("Wan Listener: test initiated to serial number, \(serial)", .debug, #function, #file, #line)
    // send a command to SmartLink to test the connection for the specified Radio
    _wanListener?.sendTlsCommand("application test_connection serial=\(serial)")
  }

  /// Initiate a smartlink connection to a radio
  /// - Parameters:
  ///   - serialNumber:       the serial number of the Radio
  ///   - holePunchPort:      the negotiated Hole Punch port number
  /// - Returns:              a WanHandle
  public func sendWanConnect(for serial: String, holePunchPort: Int) async throws -> String {
  
    return try await withCheckedThrowingContinuation{ continuation in
      _wanListener?.activeContinuation = continuation
      log("Wan Listener: Connect sent to serial \(serial)", .debug, #function, #file, #line)
      // send a command to SmartLink to request a connection to the specified Radio
      _wanListener?.sendTlsCommand("application connect serial=\(serial) hole_punch_port=\(holePunchPort))")
    }
  }

  /// Disconnect a smartlink Radio
  /// - Parameter serialNumber:         the serial number of the Radio
  public func sendWanDisconnect(for serial: String) {
    log("Wan Listener: Disconnect sent to serial \(serial)", .debug, #function, #file, #line)
    // send a command to SmartLink to request disconnection from the specified Radio
    _wanListener?.sendTlsCommand("application disconnect_users serial=\(serial)")
  }
  
  /// Disconnect a single smartlink Client
  /// - Parameters:
  ///   - serialNumber:         the serial number of the Radio
  ///   - handle:               the handle of the Client
  public func sendWanDisconnectClient(for serial: String, handle: Handle) {
    log("Wan Listener: Disconnect sent to serial \(serial), handle \(handle.hex)", .debug, #function, #file, #line)
    // send a command to SmartLink to request disconnection from the specified Radio
    _wanListener?.sendTlsCommand("application disconnect_users serial=\(serial) handle=\(handle.hex)")
  }
}
