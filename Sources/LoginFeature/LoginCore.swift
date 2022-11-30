//
//  LoginCore.swift
//  ViewComponents/LoginCore
//
//  Created by Douglas Adams on 12/28/21.
//

import Foundation
import ComposableArchitecture

import Shared

public struct LoginFeature: ReducerProtocol {
  
  public init() {}
  
  public struct State: Equatable {
    @BindableState var user: String
    @BindableState var pwd: String
    var heading: String
    var message: String?
    var userLabel: String
    var pwdLabel: String
    var labelWidth: CGFloat
    var overallWidth: CGFloat

    public init
    (
      heading: String = "Please Login",
      message: String? = nil,
      user: String = "",
      pwd: String = "",
      userLabel: String = "User",
      pwdLabel: String = "Password",
      labelWidth: CGFloat = 100,
      overallWidth: CGFloat = 350
    )
    {
      self.heading = heading
      self.message = message
      self.user = user
      self.pwd = pwd
      self.userLabel = userLabel
      self.pwdLabel = pwdLabel
      self.labelWidth = labelWidth
      self.overallWidth = overallWidth
    }
  }
  
  public enum Action: Equatable, BindableAction {
    case binding(BindingAction<State>)
    case cancelButton
    case loginButton(String, String)
  }
  
  public var body: some ReducerProtocol<State, Action> {
    BindingReducer()
  }
}
