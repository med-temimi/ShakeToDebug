    //
    //  DebugConsole.swift
    //  UIWindowDebug
    //
    //  Created by Macbook Pro  M'ed on 19/07/25.
    //

import UIKit
#if DEBUG
extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            print("🔥 DebugConsole: - Shake detected!")
            if let topVC = topViewController() {
                if let existingConsole = topVC.view.subviews.first(where: { $0 is DebugConsoleView }) {
                    existingConsole.removeFromSuperview()
                } else {
                    print("🔥 DebugConsole: - Creating new console")
                    let console = DebugConsoleView()
                    console.frame = CGRect(x: 20, y: 100,
                                           width: topVC.view.bounds.width - 40,
                                           height: topVC.view.bounds.height / 3)
                    topVC.view.addSubview(console)
                    DebugConsole.shared.addObserver(console)
                    console.update(with: DebugConsole.shared.logText)
                }
            }
        }
    }
    
    private func topViewController(base: UIViewController? = UIApplication.shared.connectedScenes
        .filter({$0.activationState == .foregroundActive})
        .map({$0 as? UIWindowScene})
        .compactMap({$0})
        .first?.windows
        .filter({$0.isKeyWindow}).first?.rootViewController) -> UIViewController? {
            if let nav = base as? UINavigationController {
                return topViewController(base: nav.visibleViewController)
            } else if let tab = base as? UITabBarController {
                return topViewController(base: tab.selectedViewController)
            } else if let presented = base?.presentedViewController {
                return topViewController(base: presented)
            }
            return base
        }
}

protocol DebugConsoleObserver: AnyObject {
    func debugConsoleDidUpdate(with text: String)
}

class DebugConsoleView: UIView, DebugConsoleObserver {
    private let textView = UITextView()
    private let clearButton = UIButton(type: .system)
    private let closeButton = UIButton(type: .system)
    
    init() {
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        DebugConsole.shared.removeObserver(self)
    }
    
    private func setupUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.85)
        layer.cornerRadius = 12
        layer.borderColor = UIColor.systemBlue.cgColor
        layer.borderWidth = 1
        
            // Text View
        textView.backgroundColor = .clear
        textView.textColor = .white
        textView.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.isEditable = false
        textView.isSelectable = true
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        
            // Clear Button
        clearButton.setTitle("Clear", for: .normal)
        clearButton.setTitleColor(.white, for: .normal)
        clearButton.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        clearButton.backgroundColor = UIColor.systemRed.withAlphaComponent(0.7)
        clearButton.layer.cornerRadius = 4
        clearButton.addTarget(self, action: #selector(clearLogs), for: .touchUpInside)
        
            // Close Button
        closeButton.setTitle("✕", for: .normal)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        closeButton.addTarget(self, action: #selector(closeConsole), for: .touchUpInside)
        
        addSubview(textView)
        addSubview(clearButton)
        addSubview(closeButton)
        setupConstraints()
    }
    
    private func setupConstraints() {
        textView.translatesAutoresizingMaskIntoConstraints = false
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            textView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            textView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            textView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -32),
            
            clearButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            clearButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            clearButton.widthAnchor.constraint(equalToConstant: 60),
            clearButton.heightAnchor.constraint(equalToConstant: 24),
            
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            closeButton.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            closeButton.widthAnchor.constraint(equalToConstant: 24),
            closeButton.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    func update(with text: String) {
        print("🔥 DebugConsole: - DebugConsoleView.update called with text: \(text.prefix(50))...") // Debug print
        DispatchQueue.main.async {
            self.textView.text = text
            self.scrollToBottom()
        }
    }
    
        // MARK: - DebugConsoleObserver
    func debugConsoleDidUpdate(with text: String) {
        update(with: text)
    }
    
    @objc private func clearLogs() {
        DebugConsole.shared.clear()
        textView.text = ""
    }
    
    @objc private func closeConsole() {
        print("🔥 DebugConsole: - Close console tapped")
        removeFromSuperview()
    }
    
    private func scrollToBottom() {
        guard textView.text.count > 0 else { return }
        let range = NSRange(location: textView.text.count - 1, length: 1)
        textView.scrollRangeToVisible(range)
    }
}

// MARK: - Debug Console Manager
class DebugConsole {
    static let shared = DebugConsole()
    private(set) var logText = ""
    private var observers: [WeakRef<AnyObject>] = []
    private let logQueue = DispatchQueue(label: "com.debugconsole.logQueue", qos: .utility)
    
    private init() {
        print("🔥 DebugConsole initialized")
    }
    
    func log(_ message: String) {
        logQueue.async {
            let timestamp = DateFormatter.logFormatter.string(from: Date())
            let formattedMessage = "[\(timestamp)] \(message)\n"
            self.logText += formattedMessage
            self.notifyObservers()
        }
    }
    
    func clear() {
        logQueue.sync {
            logText = ""
            notifyObservers()
        }
    }
    
    func addObserver(_ observer: DebugConsoleObserver) {
        cleanupObservers()
        observers.append(WeakRef(observer as AnyObject))
    }
    
    func removeObserver(_ observer: DebugConsoleObserver) {
        observers.removeAll { $0.value === observer }
    }
    
    private func cleanupObservers() {
        observers.removeAll { $0.value == nil }
    }
    
    private func notifyObservers() {
        DispatchQueue.main.async {
            self.cleanupObservers()
            for observerRef in self.observers {
                if let observer = observerRef.value as? DebugConsoleObserver {
                    observer.debugConsoleDidUpdate(with: self.logText)
                }
            }
        }
    }
}

    // MARK: - Weak Reference Wrapper
class WeakRef<T: AnyObject> {
    weak var value: T?
    
    init(_ value: T) {
        self.value = value
    }
}

    // MARK: - Date Formatter Extension
extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
}

    // MARK: - Public Interface
func debugLog(_ message: String) {
    #if DEBUG
    print("🔥 DebugConsole: - debugLog called with: \(message)")
    DebugConsole.shared.log(message)
    #endif
}

func redirectStandardOutputToDebugConsole() {
    setvbuf(stdout, nil, _IONBF, 0)
    let pipe = Pipe()
    dup2(pipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)
    pipe.fileHandleForReading.readabilityHandler = { handle in
        let data = handle.availableData
        guard !data.isEmpty else {
            return
        }
        if let string = String(data: data, encoding: .utf8) {
            if !string.contains("🔥") &&
                !string.contains("CoreAutoLayout") &&
                !string.contains("libsystem_network.dylib") {
                DispatchQueue.main.async {
                    debugLog(string.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            }
        }
    }
}
#endif
