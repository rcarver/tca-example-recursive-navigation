import SwiftUI
import ComposableArchitecture
import ComposablePresentation

// MARK: - Screen

/// ScreenState enumerates all possible screen states.
indirect enum ScreenState: Equatable {
    case counter(CounterState)
    case operators(OperatorsState)
}

/// ScreenAction handles all possible screen actions.
enum ScreenAction: Equatable {
    case counter(CounterAction)
    case operators(OperatorsAction)
}

/// ScreenEnvironment provides dependencies for all possible screens.
//
// NOTE: cannot store environments due to circular reference.
//
struct ScreenEnvironment {
    var counter: CounterEnvironment { CounterEnvironment(mainQueue: .main, uuid: UUID.init) }
    var operators: OperatorsEnvironment { OperatorsEnvironment() }
}

/// screenReducer reduces over all possible screens.
//
// NOTE: it must be a function to avoid circular references.
// NOTE: wrapping child reducers in `Reducer { }` also seems needed to avoid circular references.
//
func screenReducer() -> Reducer<ScreenState, ScreenAction, ScreenEnvironment> {
    .combine(
        Reducer { counterReducer(&$0, $1, $2) }.pullback(
            state: /ScreenState.counter,
            action: /ScreenAction.counter,
            environment: \.counter
        ),
        Reducer { operatorsReducer(&$0, $1, $2) }.pullback(
            state: /ScreenState.operators,
            action: /ScreenAction.operators,
            environment: \.operators
        )
    )
}

/// ScreenSwitchStore renders all posible screens.
struct ScreenSwitchStore: View {
    let store: Store<ScreenState, ScreenAction>
    var body: some View {
        SwitchStore(store) {
            CaseLet(
                state: /ScreenState.counter,
                action: ScreenAction.counter,
                then: CounterView.init
            )
            CaseLet(
                state: /ScreenState.operators,
                action: ScreenAction.operators,
                then: OperatorsView.init
            )
        }
    }
}

/// PresentedScreenSwitchStore renders all posible screens in all possible presentations.
struct PresentedScreenSwitchStore: View {
    let type: PresentationType
    let store: Store<ScreenState, ScreenAction>
    var body: some View {
        switch type {
        case .navigation:
            ScreenSwitchStore(store: store)
        case .sheet, .fullScreenCover:
            NavigationView {
                ScreenSwitchStore(store: store)
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
}

// MARK: - Operators

/// Operators is a feature that holds a value and lets you navigate to
/// new states that operate on that value.
struct OperatorsState: Equatable {
    var value: Double = 1
    var isFork: Bool = false
    @Presented var presentation: ScreenState?
}

indirect enum OperatorsAction: Equatable {
    case tappedAdd(Double)
    case tappedMultiply(Double)
    case tappedDivide(Double)
    case tappedCounter
    case tappedFork
    case dismiss
    case presentation(ScreenAction)
}

struct OperatorsEnvironment {
    var screen = ScreenEnvironment()
}

let operatorsReducer = Reducer<OperatorsState, OperatorsAction, OperatorsEnvironment> { state, action, environment in
    switch action {

    case .tappedAdd(let value):
        state.presentation = .operators(OperatorsState(value: state.value + value))
        return .none

    case .tappedMultiply(let value):
        state.presentation = .operators(OperatorsState(value: state.value * value))
        return .none

    case .tappedDivide(let value):
        state.presentation = .operators(OperatorsState(value: state.value / value))
        return .none

    case .tappedCounter:
        state.presentation = .counter(CounterState(counter: Int(state.value)))
        return .none

    case .tappedFork:
        state.presentation = .operators(OperatorsState(value: state.value, isFork: true))
        return .none

    case .dismiss:
        state.presentation = nil
        return .none

    case .presentation:
        return .none
    }
}
    .presented(
        screenReducer(),
        state: \.$presentation,
        action: /OperatorsAction.presentation,
        environment: \.screen
    )

struct OperatorsView: View {
    let store: Store<OperatorsState, OperatorsAction>
    var body: some View {
        WithViewStore(store) { viewStore in
            List {
                Section {
                    Button("Add 1") { viewStore.send(.tappedAdd(1)) }
                    Button("Multiply 3") { viewStore.send(.tappedMultiply(3)) }
                    Button("Divide 5") { viewStore.send(.tappedDivide(5)) }
                }
                Section {
                    Button("Counter") { viewStore.send(.tappedCounter) }
                    Button("Fork") { viewStore.send(.tappedFork) }
                }
            }
            .navigationTitle(String(describing: viewStore.value))
        }
        .presentation(
            type: { state in
                switch state {
                case .operators(let op):
                    return op.isFork ? .sheet : .detailNavigation
                case .counter:
                    return .detailNavigation
                }
            },
            store: store,
            state: \.presentation,
            action: OperatorsAction.presentation,
            dismiss: OperatorsAction.dismiss,
            destination: PresentedScreenSwitchStore.init
        )
    }
}

struct Operators_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            OperatorsView(
                store: .init(
                    initialState: .init(),
                    reducer: operatorsReducer,
                    environment: .init()
                )
            )
        }
    }
}

// MARK: - Counter

/// Counter is a feature that counts up from a value, then lets you capture
/// it by navigating to the Operators feature with the current value.
struct CounterState: Equatable {
    var id: UUID?
    var counter: Int = 0
    @Presented var operators: OperatorsState?
}

indirect enum CounterAction: Equatable {
    case start
    case tick
    case tappedCapture
    case dismiss
    case operators(OperatorsAction)
}

struct CounterEnvironment {
    var mainQueue: AnySchedulerOf<DispatchQueue>
    var uuid: () -> UUID
    var operators = OperatorsEnvironment()
}

let counterReducer = Reducer<CounterState, CounterAction, CounterEnvironment> { state, action, environment in
    switch action {
    case .start:
        if state.id == nil {
            let id = environment.uuid()
            state.id = id
            return Effect.timer(id: id, every: 0.01, on: environment.mainQueue)
                .map { _ in CounterAction.tick }
        } else {
            return .none
        }

    case .tappedCapture:
        state.operators = OperatorsState(value: Double(state.counter))
        return .none

    case .tick:
        state.counter += 1
        return .none

    case .dismiss:
        state.operators = nil
        return .none

    case .operators:
        return .none
    }
}
    .presented(
        operatorsReducer,
        state: \.$operators,
        action: /CounterAction.operators,
        environment: \.operators
    )

struct CounterView: View {
    let store: Store<CounterState, CounterAction>
    var body: some View {
        WithViewStore(store.scope(state: \.counter)) { viewStore in
            VStack {
                Text(viewStore.state.formatted(.number))
                Button("Capture") {
                    viewStore.send(.tappedCapture)
                }
            }
            .navigationTitle("Counter")
            .onAppear { viewStore.send(.start) }
        }
        .navigation(
            isDetail: true,
            store: store,
            state: \.operators,
            action: CounterAction.operators,
            dismiss: CounterAction.dismiss,
            destination: OperatorsView.init
        )
    }
}

struct Counter_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CounterView(
                store: .init(
                    initialState: .init(),
                    reducer: counterReducer,
                    environment: .init(
                        mainQueue: .main,
                        uuid: UUID.init
                    )
                )
            )
        }
    }
}
