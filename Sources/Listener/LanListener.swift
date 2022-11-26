//
//  LanListener.swift
//  ApiComponents/Api6000/Discovery
//
//  Created by Douglas Adams on 10/28/21
//  Copyright © 2021 Douglas Adams. All rights reserved.
//

import Foundation
import CocoaAsyncSocket
import Combine

import Shared
import Vita

public enum LanListenerError: Error {
  case kSocketError
  case kReceivingError
}

/// Listener implementation
///
///      listens for the udp broadcasts announcing the presence
///      of a Flex-6000 Radio, publishes changes
///
public final class LanListener: NSObject, ObservableObject {
  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _cancellables = Set<AnyCancellable>()
  private let _formatter = DateFormatter()
  private let _udpQ = DispatchQueue(label: "LanListener" + ".udpQ")
  private var _udpSocket: GCDAsyncUdpSocket!

  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  init(port: UInt16 = 4992) {
    super.init()
    
    _formatter.timeZone = .current
    _formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

    // create a Udp socket and set options
    _udpSocket = GCDAsyncUdpSocket( delegate: self, delegateQueue: _udpQ )
    _udpSocket.setPreferIPv4()
    _udpSocket.setIPv6Enabled(false)
    
    try! _udpSocket.enableReusePort(true)
    try! _udpSocket.bind(toPort: port)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Internal methods
  
  func start(checkInterval: TimeInterval = 1.0, timeout: TimeInterval = 10.0) {
    try! _udpSocket.beginReceiving()
    log("Lan Listener: STARTED", .info, #function, #file, #line)
    
    // setup a timer to watch for Radio timeouts
    Timer.publish(every: checkInterval, on: .main, in: .default)
      .autoconnect()
      .sink { now in
        PacketCollection.shared.removePackets(condition: { $0.source == .local && abs($0.lastSeen.timeIntervalSince(now)) > timeout } )
      }
      .store(in: &_cancellables)
  }
  /// stop the listener
  func stop() {
    _cancellables = Set<AnyCancellable>()
    _udpSocket?.close()
    log("Lan Listener: STOPPED", .info, #function, #file, #line)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private methods
  
  /// Parse a Vita class containing a Discovery broadcast
  /// - Parameter vita:   a Vita packet
  /// - Returns:          a DiscoveryPacket (or nil)
  private func parseVita(_ vita: Vita) -> Packet? {
    // is this a Discovery packet?
    if vita.classIdPresent && vita.classCode == .discovery {
      // Payload is a series of strings of the form <key=value> separated by ' ' (space)
      var payloadData = NSString(bytes: vita.payloadData, length: vita.payloadSize, encoding: String.Encoding.ascii.rawValue)! as String
      
      // eliminate any Nulls at the end of the payload
      payloadData = payloadData.trimmingCharacters(in: CharacterSet(charactersIn: "\0"))
      
      return Packet.populate( payloadData.keyValuesArray() )
    }
    return nil
  }
}

// ----------------------------------------------------------------------------
// MARK: - GCDAsyncUdpSocketDelegate extension

extension LanListener: GCDAsyncUdpSocketDelegate {
  /// The Socket received data
  ///
  /// - Parameters:
  ///   - sock:           the GCDAsyncUdpSocket
  ///   - data:           the Data received
  ///   - address:        the Address of the sender
  ///   - filterContext:  the FilterContext
  public func udpSocket(_ sock: GCDAsyncUdpSocket,
                        didReceive data: Data,
                        fromAddress address: Data,
                        withFilterContext filterContext: Any?) {
    // VITA packet?
    guard let vita = Vita.decode(from: data) else { return }
    
    // YES, Discovery Packet?
    guard let packet = parseVita(vita) else { return }
    
    // YES, process it
    PacketCollection.shared.processPacket(packet)
  }
}
