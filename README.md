# InjectAPK
Binding Android Payload Into APK and Remotely Hack Into Android Phone.

> ⚠️ **For Educational & Ethical Penetration Testing Only**

---

## 📁 Files

| File | Description |
|------|-------------|
| `Injectapk.sh` | **Kali Linux** version (PC/Laptop) |
| `InjectAPK_Termux.sh` | **Termux** version (Android phone) |
| `apktool.jar` | APK decompiler tool |
| `demo.apk` | Sample APK for testing |

---

## 🐧 Kali Linux Version

**Requirements:** `metasploit-framework`, `apktool`, `default-jdk`, `aapt`, `apksigner`, `apache2`, `zipalign`

```bash
sudo apt update && sudo apt install git -y
git clone https://github.com/mehedishakeel/InjectAPK.git
cd InjectAPK
sudo chmod +x Injectapk.sh
sudo ./Injectapk.sh
```

---

## 📱 Termux Edition (Android Phone)

**Requirements:** Termux app from F-Droid (NOT Play Store)

### Step 1 — Install Termux from F-Droid
Download: https://f-droid.org/packages/com.termux/

### Step 2 — Setup & Run
```bash
# Inside Termux
pkg update && pkg upgrade -y
pkg install git -y

git clone https://github.com/mehedishakeel/InjectAPK.git
cd InjectAPK

chmod +x InjectAPK_Termux.sh
./InjectAPK_Termux.sh
```

### Termux vs Kali — What's Different?

| Feature | Kali Linux | Termux |
|---------|-----------|--------|
| Package manager | `apt` | `pkg` |
| Web server | Apache2 | Python HTTP Server |
| Root required | Yes (`sudo`) | No |
| APK sharing port | Port 80 | Port 8080 |
| WAN tunnel | Manual | ngrok support built-in |
| APK location | Current dir | Auto-scans Downloads |
| Java | `default-jdk` | `openjdk-17` |

### What the Termux script does automatically:
- ✅ Installs all required packages via `pkg`
- ✅ Downloads & sets up apktool
- ✅ Generates signing keystore
- ✅ Injects payload with msfvenom
- ✅ Runs zipalign optimization
- ✅ Signs APK with apksigner
- ✅ Starts Python HTTP server for file sharing
- ✅ Optional ngrok tunnel for WAN access
- ✅ Launches Metasploit handler

---

## Watch Full Video Guide

[![Video Guide](https://img.youtube.com/vi/X77ZUo82cyw/maxresdefault.jpg)](https://youtu.be/X77ZUo82cyw)
