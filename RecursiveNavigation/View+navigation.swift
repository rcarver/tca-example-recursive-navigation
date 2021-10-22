import ComposableArchitecture
import SwiftUI

extension View {

    /// Present store as navigation.
    func navigation<State, Action, LocalState: Equatable, LocalAction, Destination: View>(
        isDetail: Bool,
        store: Store<State, Action>,
        state toLocalState: @escaping (State) -> LocalState?,
        action toLocalAction: @escaping (LocalAction) -> Action,
        dismiss: Action,
        @ViewBuilder destination: @escaping (Store<LocalState, LocalAction>) -> Destination
    ) -> some View {
        self.background(
            WithViewStore(store.scope(state: { toLocalState($0) != nil })) { viewStore in
                NavigationLink(
                    isActive: Binding(
                        get: { viewStore.state },
                        set: { if !$0 { viewStore.send(dismiss) } }
                    ),
                    destination: {
                        IfLetStore(store.scope(state: toLocalState, action: toLocalAction)) { destinationStore in
                            destination(destinationStore)
                        }
                    },
                    label: {
                        EmptyView()
                    }
                ).isDetailLink(isDetail)
            }
        )
    }

    /// Present store as sheet.
    func sheet<State, Action, LocalState: Equatable, LocalAction, Destination: View>(
        store: Store<State, Action>,
        state toLocalState: @escaping (State) -> LocalState?,
        action toLocalAction: @escaping (LocalAction) -> Action,
        dismiss: Action,
        @ViewBuilder destination: @escaping (Store<LocalState, LocalAction>) -> Destination
    ) -> some View {
        self.background(
            WithViewStore(store.scope(state: { toLocalState($0) != nil })) { viewStore in
                EmptyView()
                    .sheet(
                        isPresented: Binding(
                            get: { viewStore.state },
                            set: { if !$0 { viewStore.send(dismiss) } }
                        ),
                        content: {
                            IfLetStore(store.scope(state: toLocalState, action: toLocalAction)) { destinationStore in
                                destination(destinationStore)
                            }
                        }
                    )
            }
        )
    }
}
