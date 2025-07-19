# ShakeToDebug 🕹️  
*A zero-setup, in-app debug console for iOS developers. Shake your device to see real-time logs—no Xcode required!*  

## 🌟 Features  
- **Shake-to-toggle** debug console  
- **Log anything** (`API responses`, `state`, `errors`)  
- **Works on physical devices** & TestFlight builds  
- **DEBUG-only** (auto-excluded from App Store)  
- **Zero dependencies**  

## 🚀 Installation  
1. Drag `DebugConsole.swift` into your Xcode project.  
2. **No further setup needed!**  

## 💻 Usage  
Replace `print()` with:  
```swift  
DebugConsole.shared.log("Auth token: \(token)")
DebugConsole.shared.log("API Response: \(response.debugDescription)")  
DebugConsole.shared.log("API Error: \(error.localizedDescription)")
```

## 🎮 Quick Start  
**Shake your device to view logs!** *(Works even on TestFlight builds!)*  

---

## 🎯 **Use Cases**  
✔ **Debug TestFlight/Enterprise builds**  
✔ **Inspect API responses in real-time**  
✔ **Track user flows without Xcode**  
✔ **Share logs with QA teams** *(No more "works on my machine!")*  

---

## 🤝 **Contributing**  
PRs welcome! Here’s what we’d love to add next:  
🔹 **Log filtering** (Regex/search support)  
🔹 **Persist logs to file** (For post-mortem debugging)  
🔹 **Network request inspector** (Auto-log URLs/status codes)  
🔹 **Debug View Hierarchy** (Live Debugging views/components)  

*Have another idea? Open an issue!*  
