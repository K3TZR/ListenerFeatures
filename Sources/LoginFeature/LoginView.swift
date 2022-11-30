//
//  LoginView.swift
//
//  Created by Douglas Adams on 12/28/21.
//

import ComposableArchitecture
import SwiftUI

// ----------------------------------------------------------------------------
// MARK: - View(s)

public struct LoginView: View {
  let store: StoreOf<LoginFeature>

  public init(store: StoreOf<LoginFeature>) {
    self.store = store
  }

  public var body: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      VStack(spacing: 10) {
        Text( viewStore.heading ).font( .title2 )
        if viewStore.message != nil { Text(viewStore.message!).font(.subheadline) }
        Divider()
        HStack {
          Text( viewStore.userLabel ).frame( width: viewStore.labelWidth, alignment: .leading)
          TextField( "", text: viewStore.binding(\.$user))
        }
        HStack {
          Text( viewStore.pwdLabel ).frame( width: viewStore.labelWidth, alignment: .leading)
          SecureField( "", text: viewStore.binding(\.$pwd))
        }
        
        HStack( spacing: 60 ) {
          Button( "Cancel" ) { viewStore.send(.cancelButton) }
            .keyboardShortcut( .cancelAction )
          
          Button( "Log in" ) { viewStore.send(.loginButton(viewStore.user, viewStore.pwd)) }
            .keyboardShortcut( .defaultAction )
            .disabled( viewStore.user.isEmpty || viewStore.pwd.isEmpty )
        }
      }
      .frame( minWidth: viewStore.overallWidth )
    }
    .padding(10)
  }
}

// ----------------------------------------------------------------------------
// MARK: - Preview(s)

struct LoginView_Previews: PreviewProvider {
  static var previews: some View {
    LoginView(store: Store(
      initialState: LoginFeature.State(),
      reducer: LoginFeature())
    )
    .frame( width: 350 )
    .padding(10)
  }
}
