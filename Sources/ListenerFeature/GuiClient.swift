//
//  GuiClient.swift
//  UtilityComponents/Shared
//
//  Created by Douglas Adams on 10/28/21
//  Copyright © 2021 Douglas Adams. All rights reserved.
//

import Foundation
import Combine

import Shared

public enum ClientEventAction: String {
  case added
  case removed
  case completed
}
public struct ClientEvent: Equatable {
  
  public init(_ action: ClientEventAction, client: GuiClient) {
    self.action = action
    self.client = client
  }
  public var action: ClientEventAction
  public var client: GuiClient
}

public class GuiClient: Hashable, Equatable, Identifiable, ObservableObject {
  // ----------------------------------------------------------------------------
  // MARK: - Public properties
  public var id: Handle { handle }
  
  @Published public var clientId: GuiClientId?
  @Published public var handle: Handle = 0
  @Published public var host = ""
  @Published public var ip = ""
  @Published public var isLocalPtt = false
  @Published public var isThisClient = false
  @Published public var program = ""
  @Published public var station = ""
  
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(handle)
    hasher.combine(station)
  }
  
  // ----------------------------------------------------------------------------
  // MARK: - Initialization
  
  public init(handle: Handle, station: String, program: String,
              clientId: GuiClientId? = nil, host: String = "", ip: String = "",
              isLocalPtt: Bool = false, isThisClient: Bool = false) {
    
    self.handle = handle
    self.clientId = clientId
    self.host = host
    self.ip = ip
    self.isLocalPtt = isLocalPtt
    self.isThisClient = isThisClient
    self.program = program
    self.station = station
  }
  
  public static func == (lhs: GuiClient, rhs: GuiClient) -> Bool {
    lhs.handle == rhs.handle
  }
}
