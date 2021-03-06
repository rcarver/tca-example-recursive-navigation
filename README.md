#  TCA Recursive Navigation

An experiment of recursive navigation using [The Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture).

### Dependencies

* Uses [Composable Presentation](https://github.com/darrarski/swift-composable-presentation) for automatic cancellation of effects when state goes nil.
* Modifies Composable Presentation with [optimized cancellation via `@Published` property wrapper](https://github.com/darrarski/swift-composable-presentation/pull/4)
* Modifies Composable Presentation further with [optimized management of cancellables](https://github.com/rcarver/swift-composable-presentation/pull/1)     

### Novel Ideas

* `View.navigation` and `View.sheet` modifiers use an Action to dismiss instead of an `onDismiss` callback in Composable Presentation.
* `View.presentation` unifies all types of presentation, allowing the type to be chosen at runtime (Navigation vs Sheet for example). This lets you describe all mutually exclusive navigation paths in a single state (enum), then present them differently. Or even decide the presentation based on something inside that state.  

### The App

The app navigates through mathematical operators to modify a number. In so you can navigate infitely forward and backward. A 'counter' screen lets you capture a new number and exercises cancellable effects.

Or, "fork" the current state into a sheet and navigate independently of the initial number. Again, recursively forever.

### Highlights

Pulling that all together, the interesting parts are:

Modeling all possible navigation paths in an enum

```swift
indirect enum ScreenState: Equatable {
    case counter(CounterState)
    case operators(OperatorsState)
}
```

Rendering all of those screens with a `SwitchStore`:

```swift
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
```` 

Rendering all possible presentations of those screens:

```swift
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
```

Presenting views at runtime:

```swift
var body: some View {
    List {
        // content
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
```

### License 

MIT
