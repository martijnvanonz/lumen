import SwiftUI
import Combine

// MARK: - Advanced State Management

/// Centralized state container for complex state management
class StateContainer<State>: ObservableObject {
    @Published private(set) var state: State
    
    private let reducer: (State, Action) -> State
    private var cancellables = Set<AnyCancellable>()
    
    init(initialState: State, reducer: @escaping (State, Action) -> State) {
        self.state = initialState
        self.reducer = reducer
    }
    
    func dispatch(_ action: Action) {
        let newState = reducer(state, action)
        
        DispatchQueue.main.async {
            self.state = newState
        }
    }
    
    func dispatch(_ action: Action, completion: @escaping () -> Void) {
        dispatch(action)
        
        DispatchQueue.main.async {
            completion()
        }
    }
    
    func asyncDispatch(_ action: AsyncAction) async {
        await action.execute { [weak self] syncAction in
            self?.dispatch(syncAction)
        }
    }
}

// MARK: - Action Protocol

protocol Action {}

protocol AsyncAction {
    func execute(dispatch: @escaping (Action) -> Void) async
}

// MARK: - App State

struct AppState {
    var wallet: WalletState
    var network: NetworkState
    var ui: UIState
    var payments: PaymentState
    
    static let initial = AppState(
        wallet: WalletState(),
        network: NetworkState(),
        ui: UIState(),
        payments: PaymentState()
    )
}

// MARK: - Wallet State

struct WalletState {
    var isConnected: Bool = false
    var balance: UInt64 = 0
    var isLoading: Bool = false
    var error: String?
    var walletInfo: GetInfoResponse?
    
    enum Action: StateManagement.Action {
        case setConnected(Bool)
        case setBalance(UInt64)
        case setLoading(Bool)
        case setError(String?)
        case setWalletInfo(GetInfoResponse?)
    }
    
    static func reducer(state: WalletState, action: Action) -> WalletState {
        var newState = state
        
        switch action {
        case .setConnected(let connected):
            newState.isConnected = connected
            if !connected {
                newState.error = "Wallet disconnected"
            }
        case .setBalance(let balance):
            newState.balance = balance
        case .setLoading(let loading):
            newState.isLoading = loading
        case .setError(let error):
            newState.error = error
        case .setWalletInfo(let info):
            newState.walletInfo = info
        }
        
        return newState
    }
}

// MARK: - Network State

struct NetworkState {
    var isConnected: Bool = true
    var connectionType: NetworkMonitor.ConnectionType = .wifi
    var isExpensive: Bool = false
    var quality: NetworkQuality = .excellent
    
    enum Action: StateManagement.Action {
        case setConnected(Bool)
        case setConnectionType(NetworkMonitor.ConnectionType)
        case setExpensive(Bool)
        case setQuality(NetworkQuality)
    }
    
    static func reducer(state: NetworkState, action: Action) -> NetworkState {
        var newState = state
        
        switch action {
        case .setConnected(let connected):
            newState.isConnected = connected
        case .setConnectionType(let type):
            newState.connectionType = type
        case .setExpensive(let expensive):
            newState.isExpensive = expensive
        case .setQuality(let quality):
            newState.quality = quality
        }
        
        return newState
    }
}

// MARK: - UI State

struct UIState {
    var activeSheet: ActiveSheet?
    var showingAlert: Bool = false
    var alertMessage: String?
    var isLoading: Bool = false
    var loadingMessage: String?
    var theme: AppTheme.Mode = .system
    
    enum ActiveSheet: Identifiable {
        case send, receive, refund, walletInfo, settings
        
        var id: String {
            switch self {
            case .send: return "send"
            case .receive: return "receive"
            case .refund: return "refund"
            case .walletInfo: return "walletInfo"
            case .settings: return "settings"
            }
        }
    }
    
    enum Action: StateManagement.Action {
        case showSheet(ActiveSheet)
        case hideSheet
        case showAlert(String)
        case hideAlert
        case setLoading(Bool, String?)
        case setTheme(AppTheme.Mode)
    }
    
    static func reducer(state: UIState, action: Action) -> UIState {
        var newState = state
        
        switch action {
        case .showSheet(let sheet):
            newState.activeSheet = sheet
        case .hideSheet:
            newState.activeSheet = nil
        case .showAlert(let message):
            newState.showingAlert = true
            newState.alertMessage = message
        case .hideAlert:
            newState.showingAlert = false
            newState.alertMessage = nil
        case .setLoading(let loading, let message):
            newState.isLoading = loading
            newState.loadingMessage = message
        case .setTheme(let theme):
            newState.theme = theme
        }
        
        return newState
    }
}

// MARK: - Payment State

struct PaymentState {
    var payments: [Payment] = []
    var isLoading: Bool = false
    var filter: PaymentFilter = .all
    var selectedPayment: Payment?
    var error: String?
    
    enum Action: StateManagement.Action {
        case setPayments([Payment])
        case addPayment(Payment)
        case updatePayment(Payment)
        case setLoading(Bool)
        case setFilter(PaymentFilter)
        case selectPayment(Payment?)
        case setError(String?)
    }
    
    static func reducer(state: PaymentState, action: Action) -> PaymentState {
        var newState = state
        
        switch action {
        case .setPayments(let payments):
            newState.payments = payments
        case .addPayment(let payment):
            newState.payments.insert(payment, at: 0)
        case .updatePayment(let payment):
            if let index = newState.payments.firstIndex(where: { $0.id == payment.id }) {
                newState.payments[index] = payment
            }
        case .setLoading(let loading):
            newState.isLoading = loading
        case .setFilter(let filter):
            newState.filter = filter
        case .selectPayment(let payment):
            newState.selectedPayment = payment
        case .setError(let error):
            newState.error = error
        }
        
        return newState
    }
}

// MARK: - App State Manager

class AppStateManager: ObservableObject {
    static let shared = AppStateManager()
    
    @Published private(set) var state = AppState.initial
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupStateObservation()
    }
    
    // MARK: - Dispatch Methods
    
    func dispatch(_ action: WalletState.Action) {
        state.wallet = WalletState.reducer(state: state.wallet, action: action)
    }
    
    func dispatch(_ action: NetworkState.Action) {
        state.network = NetworkState.reducer(state: state.network, action: action)
    }
    
    func dispatch(_ action: UIState.Action) {
        state.ui = UIState.reducer(state: state.ui, action: action)
    }
    
    func dispatch(_ action: PaymentState.Action) {
        state.payments = PaymentState.reducer(state: state.payments, action: action)
    }
    
    // MARK: - Async Actions
    
    func loadWalletInfo() async {
        dispatch(WalletState.Action.setLoading(true))
        
        do {
            let walletInfo = try await WalletManager.shared.getInfo()
            dispatch(WalletState.Action.setWalletInfo(walletInfo))
            dispatch(WalletState.Action.setBalance(walletInfo.balance))
            dispatch(WalletState.Action.setError(nil))
        } catch {
            dispatch(WalletState.Action.setError(error.localizedDescription))
        }
        
        dispatch(WalletState.Action.setLoading(false))
    }
    
    func loadPayments() async {
        dispatch(PaymentState.Action.setLoading(true))
        
        do {
            let payments = try await WalletManager.shared.listPayments()
            dispatch(PaymentState.Action.setPayments(payments))
            dispatch(PaymentState.Action.setError(nil))
        } catch {
            dispatch(PaymentState.Action.setError(error.localizedDescription))
        }
        
        dispatch(PaymentState.Action.setLoading(false))
    }
    
    func sendPayment(_ request: PrepareSendRequest) async {
        dispatch(UIState.Action.setLoading(true, "Sending payment..."))
        
        do {
            let response = try await WalletManager.shared.sendPayment(req: request)
            dispatch(PaymentState.Action.addPayment(response.payment))
            dispatch(UIState.Action.showAlert("Payment sent successfully!"))
        } catch {
            dispatch(UIState.Action.showAlert("Payment failed: \(error.localizedDescription)"))
        }
        
        dispatch(UIState.Action.setLoading(false, nil))
    }
    
    // MARK: - State Observation
    
    private func setupStateObservation() {
        // Observe wallet manager changes
        WalletManager.shared.$isConnected
            .sink { [weak self] isConnected in
                self?.dispatch(WalletState.Action.setConnected(isConnected))
            }
            .store(in: &cancellables)
        
        WalletManager.shared.$balance
            .sink { [weak self] balance in
                self?.dispatch(WalletState.Action.setBalance(balance))
            }
            .store(in: &cancellables)
        
        // Observe network changes
        NetworkMonitor.shared.$isConnected
            .sink { [weak self] isConnected in
                self?.dispatch(NetworkState.Action.setConnected(isConnected))
            }
            .store(in: &cancellables)
        
        NetworkMonitor.shared.$connectionType
            .sink { [weak self] type in
                self?.dispatch(NetworkState.Action.setConnectionType(type))
            }
            .store(in: &cancellables)
    }
}

// MARK: - State Binding Helpers

extension AppStateManager {
    var walletBinding: Binding<WalletState> {
        Binding(
            get: { self.state.wallet },
            set: { _ in } // Read-only binding
        )
    }
    
    var networkBinding: Binding<NetworkState> {
        Binding(
            get: { self.state.network },
            set: { _ in } // Read-only binding
        )
    }
    
    var uiBinding: Binding<UIState> {
        Binding(
            get: { self.state.ui },
            set: { _ in } // Read-only binding
        )
    }
    
    var paymentsBinding: Binding<PaymentState> {
        Binding(
            get: { self.state.payments },
            set: { _ in } // Read-only binding
        )
    }
}

// MARK: - View Extensions

extension View {
    /// Inject app state into view hierarchy
    func withAppState() -> some View {
        self.environmentObject(AppStateManager.shared)
    }
    
    /// Access specific state slice
    func withWalletState<Content: View>(
        @ViewBuilder content: @escaping (WalletState) -> Content
    ) -> some View {
        self.modifier(StateAccessModifier(
            keyPath: \.wallet,
            content: content
        ))
    }
    
    func withNetworkState<Content: View>(
        @ViewBuilder content: @escaping (NetworkState) -> Content
    ) -> some View {
        self.modifier(StateAccessModifier(
            keyPath: \.network,
            content: content
        ))
    }
    
    func withUIState<Content: View>(
        @ViewBuilder content: @escaping (UIState) -> Content
    ) -> some View {
        self.modifier(StateAccessModifier(
            keyPath: \.ui,
            content: content
        ))
    }
    
    func withPaymentState<Content: View>(
        @ViewBuilder content: @escaping (PaymentState) -> Content
    ) -> some View {
        self.modifier(StateAccessModifier(
            keyPath: \.payments,
            content: content
        ))
    }
}

// MARK: - State Access Modifier

struct StateAccessModifier<StateSlice, Content: View>: ViewModifier {
    let keyPath: KeyPath<AppState, StateSlice>
    let content: (StateSlice) -> Content
    
    @EnvironmentObject private var stateManager: AppStateManager
    
    func body(content: Content) -> some View {
        self.content(stateManager.state[keyPath: keyPath])
    }
}

// MARK: - Computed State Properties

extension AppState {
    var filteredPayments: [Payment] {
        switch payments.filter {
        case .all:
            return payments.payments
        case .sent:
            return payments.payments.filter { $0.paymentType == .send }
        case .received:
            return payments.payments.filter { $0.paymentType == .receive }
        case .pending:
            return payments.payments.filter { $0.status == .pending }
        case .completed:
            return payments.payments.filter { $0.status == .complete }
        case .failed:
            return payments.payments.filter { $0.status == .failed }
        }
    }
    
    var isFullyLoaded: Bool {
        !wallet.isLoading && !payments.isLoading && !ui.isLoading
    }
    
    var hasErrors: Bool {
        wallet.error != nil || payments.error != nil
    }
    
    var networkQuality: NetworkQuality {
        if !network.isConnected {
            return .offline
        }
        
        switch network.connectionType {
        case .wifi, .ethernet:
            return .excellent
        case .cellular:
            return network.isExpensive ? .fair : .good
        case .other:
            return .good
        case .none:
            return .offline
        }
    }
}

// MARK: - State Persistence

extension AppStateManager {
    private var stateKey: String { "app_state" }
    
    func saveState() {
        do {
            let data = try JSONEncoder().encode(state)
            UserDefaults.standard.set(data, forKey: stateKey)
        } catch {
            print("Failed to save state: \(error)")
        }
    }
    
    func loadState() {
        guard let data = UserDefaults.standard.data(forKey: stateKey) else { return }
        
        do {
            let savedState = try JSONDecoder().decode(AppState.self, from: data)
            self.state = savedState
        } catch {
            print("Failed to load state: \(error)")
        }
    }
}

// MARK: - State Extensions for Codable

extension AppState: Codable {}
extension WalletState: Codable {}
extension NetworkState: Codable {}
extension UIState: Codable {}
extension PaymentState: Codable {}
extension UIState.ActiveSheet: Codable {}

// MARK: - Network Quality

enum NetworkQuality: String, Codable, CaseIterable {
    case excellent, good, fair, poor, offline
    
    var color: Color {
        switch self {
        case .excellent, .good: return AppTheme.Colors.success
        case .fair: return AppTheme.Colors.warning
        case .poor, .offline: return AppTheme.Colors.error
        }
    }
    
    var displayName: String {
        rawValue.capitalized
    }
}
