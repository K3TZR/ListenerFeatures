//
//  PacketCollection.swift
//  
//
//  Created by Douglas Adams on 9/25/22.
//

import Foundation
import IdentifiedCollections
import SwiftUI

import Shared
import Vita

public class PacketCollection: ObservableObject {
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  public static var shared = PacketCollection()
  private init() {}

  // ----------------------------------------------------------------------------
  // MARK: - Public AsyncStreams
  
  public var clientStream: AsyncStream<ClientEvent> {
    AsyncStream { continuation in _clientStream = { clientEvent in continuation.yield(clientEvent) }
      continuation.onTermination = { @Sendable _ in } }}
  
  public var packetStream: AsyncStream<PacketEvent> {
    AsyncStream { continuation in _packetStream = { packetEvent in continuation.yield(packetEvent) }
      continuation.onTermination = { @Sendable _ in } }}
  
  // ----------------------------------------------------------------------------
  // MARK: - Published properties
  
  @Published public var packets = IdentifiedArrayOf<Packet>()
  @Published public var guiClients = IdentifiedArrayOf<GuiClient>()
  
  @Published public var pickableRadios = IdentifiedArrayOf<Pickable>()
  @Published public var pickableStations = IdentifiedArrayOf<Pickable>()

  // ----------------------------------------------------------------------------
  // MARK: - Private properties
  
  private var _clientStream: (ClientEvent) -> Void = { _ in }
  private var _packetStream: (PacketEvent) -> Void = { _ in }

  private let _formatter = DateFormatter()
  
  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  /// Process an incoming DiscoveryPacket
  /// - Parameter newPacket: the packet
  func processPacket(_ newPacket: Packet) {
    
    // is it a Radio that has been seen previously?
    if let oldPacket = packets[id: newPacket.serial + newPacket.publicIp] {
      // KNOWN RADIO, check the GuiClients

      // has it changed?
      if newPacket.isDifferent(from: oldPacket) {
        // YES, update packets & Gui Clients
        parsePacket(newPacket, oldPacket)
        return
        
      } else {
        // KNOWN RADIO, no change, update the timestamp
        addUpdatePacket(newPacket)
        return
      }
    }
    // UNKNOWN RADIO, update packets & Gui Clients
    parsePacket(newPacket)
  }
  
  func parsePacket(_ newPacket: Packet, _ oldPacket: Packet? = nil) {
    // parse the received Gui Clients
    let receivedGuiClients = parseGuiClients(newPacket)
    
    // identify and report any changes
    checkGuiClients(receivedGuiClients, oldPacket)
    
    // add/update packets & guiClients
    addUpdatePacket(newPacket)
    addUpdateGuiClients(receivedGuiClients)
    
    // publish and log
    _packetStream( PacketEvent(oldPacket == nil ? .added : .updated, packet: (packets[id: newPacket.serial + newPacket.publicIp])!) )
    log("\(newPacket.source == .local ? "Lan" : "Wan") Listener: packet \(oldPacket == nil ? "ADDED" : "UPDATED"), \(newPacket.nickname) \(newPacket.serial)", .info, #function, #file, #line)
  }
  
  /// Identify added and removed Gui Clients
  /// - Parameter newGuiClients: the latest GuiClients parse
  func checkGuiClients(_ receivedGuiClients: IdentifiedArrayOf<GuiClient>, _ oldPacket: Packet? = nil) {
    
    if oldPacket == nil {
      for guiClient in receivedGuiClients {
        Task { await MainActor.run { appendGuiClient( guiClient ) }}
        _clientStream( ClientEvent(.added, client: guiClient))
      }
      
    } else {
      for guiClient in receivedGuiClients.elements.added(to: PacketCollection.shared.guiClients.elements) {
        appendGuiClient( guiClient )
        _clientStream( ClientEvent(.added, client: guiClient))
      }
      
      for guiClient in receivedGuiClients.elements.removed(from: PacketCollection.shared.guiClients.elements) {
        removeGuiClient( guiClient )
        _clientStream( ClientEvent(.removed, client: guiClient))
        log("\(oldPacket!.source == .local ? "Lan" : "Wan") Listener: guiClient REMOVED, \(guiClient.station)", .info, #function, #file, #line)
      }
    }
  }
  
  /// Remove one or more packets meeting the condition
  /// - Parameter condition: a closure defining the condition
  func removePackets(condition: @escaping (Packet) -> Bool) {
    _formatter.timeStyle = .long
    _formatter.dateStyle = .none
    for packet in packets where condition(packet) {
      removePacket(packet)
      _packetStream( PacketEvent(.deleted, packet: packet) )
      log("\(packet.source == .local ? "Lan" : "Wan") Listener: packet REMOVED, \(packet.nickname) \(packet.serial) @ " + _formatter.string(from: packet.lastSeen), .info, #function, #file, #line)
    }
  }
  
  /// FIndthe first packet meeting the condition
  /// - Parameter condition: a closure defining the condition
  func findPacket(condition: @escaping (Packet) -> Bool) -> Packet? {
    for packet in packets where condition(packet) {
      return packet
    }
    return nil
  }
  
  /// Produce an IdentifiedArray of Radios that can be picked
  func getPickableRadios() -> IdentifiedArrayOf<Pickable> {
    var pickables = IdentifiedArrayOf<Pickable>()
    for packet in packets {
      pickables.append( Pickable(id: UUID(),
                                 packet: packet,
                                 station: packet.guiClientStations,
                                 isDefault: false))
    }
    return pickables
  }

  /// Produce an IdentifiedArray of Stations that can be picked
  func getPickableStations() -> IdentifiedArrayOf<Pickable> {
    var pickables = IdentifiedArrayOf<Pickable>()
    for packet in packets {
      for guiClient in PacketCollection.shared.guiClients {
        pickables.append( Pickable(id: UUID(),
                                   packet: packet,
                                   station: guiClient.station,
                                   isDefault: false))
      }
    }
    return pickables
  }
  
  /// Determine if a GuiClient is fully populated
  /// - Parameter client: the guiClient
  func checkCompletion(_ client: GuiClient?) {
    if let client {
      
      // log & notify if all essential properties are present
      if client.handle != 0 && client.clientId != nil && client.program != "" && client.station != "" {
        log("Packets: guiClient COMPLETED: \(client.handle.hex), \(client.station), \(client.program), \(client.clientId!)", .info, #function, #file, #line)
        _clientStream( ClientEvent(.completed, client: client) )
      }
    }
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Private methods
  
  /// Parse the GuiClient CSV fields in a packet
  private func parseGuiClients(_ packet: Packet) -> IdentifiedArrayOf<GuiClient> {
    var guiClients = IdentifiedArrayOf<GuiClient>()
    
    guard packet.guiClientPrograms != "" && packet.guiClientStations != "" && packet.guiClientHandles != "" else { return guiClients }
    
    let programs  = packet.guiClientPrograms.components(separatedBy: ",")
    let stations  = packet.guiClientStations.components(separatedBy: ",")
    let handles   = packet.guiClientHandles.components(separatedBy: ",")
    let ips       = packet.guiClientIps.components(separatedBy: ",")
    
    guard programs.count == handles.count && stations.count == handles.count && ips.count == handles.count else { return guiClients }
    
    for i in 0..<handles.count {
      // add/update if valid fields
      if let handle = handles[i].handle, stations[i] != "", programs[i] != "" , ips[i] != "" {
        // add/update the collection
        guiClients[id: handle] = GuiClient(handle: handle,
                                           station: stations[i],
                                           program: programs[i],
                                           ip: ips[i])
      }
    }
    return guiClients
  }
  
  private func addUpdatePacket(_ packet: Packet) {
    Task {
      await MainActor.run {
        packets[id: packet.serial + packet.publicIp] = packet
        pickableRadios = getPickableRadios()
      }
    }
  }
  private func removePacket(_ packet: Packet) {
    Task {
      await MainActor.run {
        packets.remove(id: packet.serial + packet.publicIp)
        pickableRadios = getPickableRadios()
      }
    }
  }
  private func addUpdateGuiClients(_ guiClients: IdentifiedArrayOf<GuiClient>) {
    Task {
      await MainActor.run {
        self.guiClients = guiClients
        pickableStations = getPickableStations()
      }
    }
  }
  private func appendGuiClient(_ guiClient: GuiClient) {
    Task {
      await MainActor.run {
        guiClients.append(guiClient)
        pickableStations = getPickableStations()
      }
    }
  }
  private func removeGuiClient(_ guiClient: GuiClient) {
    Task {
      await MainActor.run {
        guiClients.remove(guiClient)
        pickableStations = getPickableStations()
      }
    }
  }
}

// ----------------------------------------------------------------------------
// MARK: - Array Extensions

extension Array where Element: Hashable {
  func removed(from other: [Element]) -> [Element] {
    let thisSet = Set(self)
    let otherSet = Set(other)
    return Array(otherSet.subtracting(thisSet))
  }
  
  func added(to other: [Element]) -> [Element] {
    let thisSet = Set(self)
    let otherSet = Set(other)
    return Array(thisSet.subtracting(otherSet))
  }
}
