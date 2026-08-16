# 🎬 Pornio-Multiplex

> **A native 4-screen hardware-accelerated Stremio multiplexing player built with Qt 6, Rust, and libmpv.**

[![Release](https://img.shields.io/badge/release-v0.1.0--beta-purple.svg)](https://github.com/Bamove6969/Pornio-Multiplex/releases)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Framework](https://img.shields.io/badge/Qt-6.7.2-brightgreen.svg)](https://qt.io)
[![Core](https://img.shields.io/badge/Rust-1.80+-orange.svg)](https://www.rust-lang.org)
[![Engine](https://img.shields.io/badge/libmpv-v2-red.svg)](https://mpv.io)

---

## 📌 Overview

**Pornio-Multiplex** is a high-performance native desktop client designed to split your screen into a dynamic **2x2 Quad-View Grid** (top-left, top-right, bottom-left, bottom-right), playing **4 distinct video streams concurrently** with independent audio routing, synchronized master controls, and native hardware acceleration.

Built as an open-source native fork for the Stremio ecosystem, Pornio-Multiplex interfaces seamlessly with **Stremio Addon Protocol v3**, supporting custom torrent streaming engines, Cinemeta catalog discovery, and live **Real-Debrid** high-speed stream resolution.

---

## ✨ Key Features

### 🎛️ 1. 4-Way 2x2 Viewport Engine
* **25% Screen Allocation**: Divides screen estate evenly into 4 active quadrants with automatic aspect-ratio preservation (`--keepaspect=yes`).
* **Independent Controls**: Each quadrant features its own hoverable overlay with real-time scrubbers, time elapsed/duration display, and individual play/pause toggles.
* **Hardware-Accelerated Decoding**: Leverages `libmpv` with `--hwdec=auto-safe` mapped directly into Qt OpenGL Framebuffer Objects (`QQuickFramebufferObject`), guaranteeing silky smooth multi-stream 1080p/4K playback with minimal CPU usage.

### 🔊 2. Dynamic Audio Focus Routing
* **Zero Sound Clashing**: Keeps 3 background streams muted while seamlessly directing audio to the active quadrant.
* **Instant Hotkeys**: Switch audio focus instantly using keys **`1`**, **`2`**, **`3`**, or **`4`** (or by clicking any quadrant).
* **Live Audio Badges**: Glowing indicator badges highlight exactly which stream currently owns the audio channel.

### 🔍 3. Solo Mode Expansion
* **1-Click Fullscreen Zoom**: Double-click any quadrant or press the **`Solo`** button to expand that stream to 100% of the screen.
* **Instant Return**: Press **`Esc`** or click **`2x2`** to restore the 4-way multiplex view without interrupting playback.

### 🌐 4. Stremio Addon Protocol v3 & Real-Debrid Integration
* **Custom Backend Native Compatibility**: Connects directly to local/remote Stremio torrent stream engines, Jackett, TPDB, and Stash indexers.
* **Real-Debrid Instant Streams**: Resolves unthrottled, high-speed cached Real-Debrid streams (`[RD+] High Speed`) with 1-click slot loading.
* **Universal Search**: Multi-tab search modal allowing instant switching between your custom backend, Cinemeta catalog, and direct HTTP/HTTPS stream links.

---

## ⌨️ Global Keybindings

| Keybinding | Action |
| :--- | :--- |
| **`1`**, **`2`**, **`3`**, **`4`** | Switch unmuted **Audio Focus** to that slot |
| **`Ctrl + 1`** .. **`Ctrl + 4`** | Open **Search / Stream Selector** for that slot |
| **Double-Click Viewport** | Toggle **Solo Maximization** (100% View / 2x2 Grid) |
| **`Esc`** | Exit Solo Mode back to 2x2 Grid |
| **`Space`** | Master **Play / Pause All** active streams |
| **`F11`** | Toggle True Fullscreen Window |

---

## 🏗️ Architectural Commitments

Pornio-Multiplex was architected around three non-negotiable engineering principles:

1. **Native Performance Over Web Bloat**:
   By replacing embedded web-views with a native **Rust FFI Core** and **Qt 6 QML / OpenGL scene graph**, Pornio-Multiplex renders 4 concurrent video streams at a fraction of the RAM and CPU consumption of Electron-based players.
2. **Non-Destructive Modularity**:
   Pornio-Multiplex operates as a completely standalone client. It connects to your existing Stremio backend, indexers, and addons over clean HTTP Stremio Protocol v3 without modifying, overwriting, or altering your existing backend files.
3. **Memory Safety & Hardware Acceleration**:
   Async networking, JSON marshaling, and state management are isolated within a safe Rust runtime, while video presentation uses native GPU swapchains (`QOpenGLFramebufferObject`).

---

## 👥 Authors & Contributors

* **Bamove6969** ([@Bamove6969](https://github.com/Bamove6969)) — *Creator & Maintainer*
* **Antigravity** (Google DeepMind) — *Architect & Core Developer*

---

## 🚀 Building & Running from Source

### Prerequisites
* **Windows 10 / 11 64-bit**
* **Rust Toolchain**: `stable-x86_64-pc-windows-gnu`
* **Qt 6.7+ (MinGW 64-bit)**
* **MinGW GCC 13+**
* **CMake 3.16+ & Ninja**

### Automated Build
Run the automated build script in PowerShell:
```powershell
.\scripts\build.ps1
```

### Launch Executable
```powershell
cd build
.\stremio-multiview.exe
```

---

## 📦 Release Information

* **Version**: `v0.1.0-beta`
* **Status**: Initial Beta Release — Stable 4-Screen Playback, Real-Debrid streaming, and Audio Focus routing.

---

## 📄 License
Released under the [MIT License](LICENSE).
