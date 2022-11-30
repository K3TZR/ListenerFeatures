//
//  Packet.swift
//  UtilityComponents/Shared
//
//  Created by Douglas Adams on 10/28/21
//  Copyright © 2021 Douglas Adams. All rights reserved.
//

import Foundation
import IdentifiedCollections

import Shared

// ----------------------------------------------------------------------------
// MARK: - Public structs and enums

public enum PacketSource: String, Equatable {
  case local = "Local"
  case smartlink = "Smartlink"
}

public enum PacketAction: String {
  case added
  case deleted
  case updated
}

public struct PacketEvent: Equatable {
  public var action: PacketAction
  public var packet: Packet

  public init(_ action: PacketAction, packet: Packet) {
    self.action = action
    self.packet = packet
  }
}

public struct Pickable: Identifiable, Equatable {
  public var id: UUID
  public var packet: Packet
  public var station: String
  public var isDefault: Bool

  public init(
    id: UUID = UUID(),
    packet: Packet,
    station: String,
    isDefault: Bool
  )
  {
    self.id = id
    self.packet = packet
    self.station = station
    self.isDefault = isDefault
  }
}


// ----------------------------------------------------------------------------
// MARK: - Packet struct

public class Packet: Identifiable, Equatable, Hashable, ObservableObject {
  
  public init(source: PacketSource = .local, nickname: String = "", status: String = "", guiClientStations: String = "") {
    lastSeen = Date() // now
    self.source = source
  }

  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  
  // these fields are NOT in the received packet but are in the Packet struct
//  @Published public var guiClients = IdentifiedArrayOf<GuiClient>()
  public var id: String { serial + publicIp }
  public var isPortForwardOn = false
  public var lastSeen: Date
  public var localInterfaceIP = ""
  public var negotiatedHolePunchPort = 0
  public var requiresHolePunch = false
  public var source: PacketSource
  public var wanHandle = ""

  // PACKET TYPE                                     LAN   WAN

  // these fields in the received packet ARE COPIED to the Packet struct
  public var callsign = ""                        //  X     X
  public var guiClientHandles = ""                //  X     X
  public var guiClientPrograms = ""               //  X     X
  public var guiClientStations = ""               //  X     X
  public var guiClientHosts = ""                  //  X     X
  public var guiClientIps = ""                    //  X     X
  public var inUseHost = ""                       //  X     X
  public var inUseIp = ""                         //  X     X
  public var model = ""                           //  X     X
  public var nickname = ""                        //  X     X   in WAN as "radio_name"
  public var port = 0                             //  X
  public var publicIp = ""                        //  X     X   in LAN as "ip"
  public var publicTlsPort: Int?                  //        X
  public var publicUdpPort: Int?                  //        X
  public var publicUpnpTlsPort: Int?              //        X
  public var publicUpnpUdpPort: Int?              //        X
  public var serial = ""                          //  X     X
  public var status = ""                          //  X     X
  public var upnpSupported = false                //        X
  public var version = ""                         //  X     X

  // these fields in the received packet ARE NOT COPIED to the Packet struct
//  public var availableClients = 0                 //  X         ignored
//  public var availablePanadapters = 0             //  X         ignored
//  public var availableSlices = 0                  //  X         ignored
//  public var discoveryProtocolVersion = ""        //  X         ignored
//  public var fpcMac = ""                          //  X         ignored
//  public var licensedClients = 0                  //  X         ignored
//  public var maxLicensedVersion = ""              //  X     X   ignored
//  public var maxPanadapters = 0                   //  X         ignored
//  public var maxSlices = 0                        //  X         ignored
//  public var radioLicenseId = ""                  //  X     X   ignored
//  public var requiresAdditionalLicense = false    //  X     X   ignored
//  public var wanConnected = false                 //  X         ignored

  // ----------------------------------------------------------------------------
  // MARK: - Private enums
  
  private enum DiscoveryTokens : String {
    case lastSeen                   = "last_seen"
    
    case availableClients           = "available_clients"
    case availablePanadapters       = "available_panadapters"
    case availableSlices            = "available_slices"
    case callsign
    case discoveryProtocolVersion   = "discovery_protocol_version"
    case version                    = "version"
    case fpcMac                     = "fpc_mac"
    case guiClientHandles           = "gui_client_handles"
    case guiClientHosts             = "gui_client_hosts"
    case guiClientIps               = "gui_client_ips"
    case guiClientPrograms          = "gui_client_programs"
    case guiClientStations          = "gui_client_stations"
    case inUseHost                  = "inuse_host"
    case inUseHostWan               = "inusehost"
    case inUseIp                    = "inuse_ip"
    case inUseIpWan                 = "inuseip"
    case licensedClients            = "licensed_clients"
    case maxLicensedVersion         = "max_licensed_version"
    case maxPanadapters             = "max_panadapters"
    case maxSlices                  = "max_slices"
    case model
    case nickname                   = "nickname"
    case port
    case publicIp                   = "ip"
    case publicIpWan                = "public_ip"
    case publicTlsPort              = "public_tls_port"
    case publicUdpPort              = "public_udp_port"
    case publicUpnpTlsPort          = "public_upnp_tls_port"
    case publicUpnpUdpPort          = "public_upnp_udp_port"
    case radioLicenseId             = "radio_license_id"
    case radioName                  = "radio_name"
    case requiresAdditionalLicense  = "requires_additional_license"
    case serial                     = "serial"
    case status
    case upnpSupported              = "upnp_supported"
    case wanConnected               = "wan_connected"
  }

  // ----------------------------------------------------------------------------
  // MARK: - Public methods
  
  public static func ==(lhs: Packet, rhs: Packet) -> Bool {
    // same serial number
    return lhs.serial == rhs.serial && lhs.publicIp == rhs.publicIp
  }
  
  public func isDifferent(from knownPacket: Packet) -> Bool {
    // status
    guard status == knownPacket.status else { return true }
    //    guard self.availableClients == currentPacket.availableClients else { return true }
    //    guard self.availablePanadapters == currentPacket.availablePanadapters else { return true }
    //    guard self.availableSlices == currentPacket.availableSlices else { return true }
    // GuiClient
    guard self.guiClientHandles == knownPacket.guiClientHandles else { return true }
    guard self.guiClientPrograms == knownPacket.guiClientPrograms else { return true }
    guard self.guiClientStations == knownPacket.guiClientStations else { return true }
//    guard self.guiClientHosts == knownPacket.guiClientHosts else { return true }
//    guard self.guiClientIps == knownPacket.guiClientIps else { return true }
    // networking
    guard port == knownPacket.port else { return true }
    guard inUseHost == knownPacket.inUseHost else { return true }
    guard inUseIp == knownPacket.inUseIp else { return true }
    guard publicIp == knownPacket.publicIp else { return true }
    guard publicTlsPort == knownPacket.publicTlsPort else { return true }
    guard publicUdpPort == knownPacket.publicUdpPort else { return true }
    guard publicUpnpTlsPort == knownPacket.publicUpnpTlsPort else { return true }
    guard publicUpnpUdpPort == knownPacket.publicUpnpUdpPort else { return true }
    // user fields
    guard callsign == knownPacket.callsign else { return true }
    guard model == knownPacket.model else { return true }
    guard nickname == knownPacket.nickname else { return true }
    return false
  }
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(publicIp)
  }


  // ----------------------------------------------------------------------------
  // MARK: - Static Public methods
  
  public static func populate(_ properties: KeyValuesArray) -> Packet {
    // create a minimal packet with now as "lastSeen"
    let packet = Packet()
    
    // process each key/value pair, <key=value>
    for property in properties {
      // check for unknown Keys
      guard let token = DiscoveryTokens(rawValue: property.key) else {
        // log it and ignore the Key
        #if DEBUG
        fatalError("Discovery: Unknown property - \(property.key) = \(property.value)")
        #else
        continue
        #endif
      }
      switch token {
        
        // these fields in the received packet are copied to the Packet struct
      case .callsign:                   packet.callsign = property.value
      case .guiClientHandles:           packet.guiClientHandles = property.value.replacingOccurrences(of: "\u{7F}", with: "")
      case .guiClientHosts:             packet.guiClientHosts = property.value.replacingOccurrences(of: "\u{7F}", with: "")
      case .guiClientIps:               packet.guiClientIps = property.value.replacingOccurrences(of: "\u{7F}", with: "")
      case .guiClientPrograms:          packet.guiClientPrograms = property.value.replacingOccurrences(of: "\u{7F}", with: "")
      case .guiClientStations:          packet.guiClientStations = property.value.replacingOccurrences(of: "\u{7F}", with: "")
      case .inUseHost, .inUseHostWan:   packet.inUseHost = property.value
      case .inUseIp, .inUseIpWan:       packet.inUseIp = property.value
      case .model:                      packet.model = property.value
      case .nickname, .radioName:       packet.nickname = property.value
      case .port:                       packet.port = property.value.iValue
      case .publicIp, .publicIpWan:     packet.publicIp = property.value
      case .publicTlsPort:              packet.publicTlsPort = property.value.iValueOpt
      case .publicUdpPort:              packet.publicUdpPort = property.value.iValueOpt
      case .publicUpnpTlsPort:          packet.publicUpnpTlsPort = property.value.iValueOpt
      case .publicUpnpUdpPort:          packet.publicUpnpUdpPort = property.value.iValueOpt
      case .serial:                     packet.serial = property.value
      case .status:                     packet.status = property.value
      case .upnpSupported:              packet.upnpSupported = property.value.bValue
      case .version:                    packet.version = property.value

        // these fields in the received packet are NOT copied to the Packet struct
      case .availableClients:           break // ignored
      case .availablePanadapters:       break // ignored
      case .availableSlices:            break // ignored
      case .discoveryProtocolVersion:   break // ignored
      case .fpcMac:                     break // ignored
      case .licensedClients:            break // ignored
      case .maxLicensedVersion:         break // ignored
      case .maxPanadapters:             break // ignored
      case .maxSlices:                  break // ignored
      case .radioLicenseId:             break // ignored
      case .requiresAdditionalLicense:  break // ignored
      case .wanConnected:               break // ignored

        // satisfy the switch statement
      case .lastSeen:                   break
      }
    }
    return packet
  }
}
