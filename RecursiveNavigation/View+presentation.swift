import ComposableArchitecture
import SwiftUI

/// All types of presentation.
enum PresentationType: Equatable {

    /// Navigation presentation, to detail or primary column.
    case navigation(isDetail: Bool)

    /// Sheet presentation.
    case sheet

    /// Full Screen presentation.
    case fullScreenCover
}

extension PresentationType {

    /// Navigation to primary column.
    static var primaryNavigation: Self { .navigation(isDetail: false) }

    /// Navigation to detail column.
    static var detailNavigation: Self { .navigation(isDetail: true) }
}

extension View {

    /// Present store by deciding the type of presentation at runtime.
    func presentation<State, Action, LocalState: Equatable, LocalAction, Destination: View>(
        type mapType: @escaping (LocalState) -> PresentationType,
        store: Store<State, Action>,
        state toLocalState: @escaping (State) -> LocalState?,
        action toLocalAction: @escaping (LocalAction) -> Action,
        dismiss: Action,
        @ViewBuilder destination: @escaping (PresentationType, Store<LocalState, LocalAction>) -> Destination
    ) -> some View {
        self.background(
            PresentationStore(
                mapType: mapType,
                store: store,
                toLocalState: toLocalState,
                toLocalAction: toLocalAction,
                dismiss: dismiss,
                destination: destination
            )
        )
    }
}

fileprivate struct PresentationStore<State, Action, LocalState: Equatable, LocalAction, Destination: View>: View {

    let mapType: (LocalState) -> PresentationType
    let store: Store<State, Action>
    let toLocalState: (State) -> LocalState?
    let toLocalAction: (LocalAction) -> Action
    let dismiss: Action
    @ViewBuilder let destination: (PresentationType, Store<LocalState, LocalAction>) -> Destination

    var body: some View {
        WithViewStore(store.scope(state: makeViewState)) { viewStore in

            // All presentation options must be present, triggered via their isActive or equivalent.
            // If not, they won't animate correctly.

            NavigationLink(
                isActive: Binding(
                    get: { isNavigation(viewStore.state) },
                    set: { if !$0 { viewStore.send(dismiss) } }
                ),
                destination: { makeDestination(store, viewStore.state) },
                label: { EmptyView() }
            )
                .isDetailLink(isDetailNavigation(viewStore.state))

                .sheet(
                    isPresented: Binding(
                        get: { isSheet(viewStore.state) },
                        set: { if !$0 { viewStore.send(dismiss) } }
                    ),
                    content: { makeDestination(store, viewStore.state) }
                )

                .fullScreenCover(
                    isPresented: Binding(
                        get: { isFullScreenCover(viewStore.state) },
                        set: { if !$0 { viewStore.send(dismiss) } }
                    ),
                    content: { makeDestination(store, viewStore.state) }
                )
        }
    }
}

private extension PresentationStore {

    func makeViewState(state: State?) -> PresentationType? {
        if let state = state, let localState = toLocalState(state) {
            return mapType(localState)
        } else {
            return nil
        }
    }

    @ViewBuilder
    func makeDestination(_ store: Store<State, Action>, _ type: PresentationType?) -> some View {
        if let type = type {
            IfLetStore(store.scope(state: toLocalState, action: toLocalAction)) { destinationStore in
                destination(type, destinationStore)
            }
        }
    }

    func isNavigation(_ type: PresentationType?) -> Bool {
        if case .navigation = type { return true }
        return false
    }

    func isDetailNavigation(_ type: PresentationType?) -> Bool {
        if case .navigation(isDetail: true) = type { return true }
        return false
    }

    func isSheet(_ type: PresentationType?) -> Bool {
        if case .sheet = type { return true }
        return false
    }

    func isFullScreenCover(_ type: PresentationType?) -> Bool {
        if case .fullScreenCover = type { return true }
        return false
    }
}
