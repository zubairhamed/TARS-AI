#!/bin/bash
# New Build Script with Retry Mechanism for pip install
# v0.4 TeknikL

set -e  # Exit on any error

# Function to retry pip install if it fails
retry_pip_install() {
    local n=1
    local max=5  # Maximum number of attempts
    local delay=5 # Delay in seconds

    while true; do
        pip install -r requirements.txt && break || {
            if [[ $n -lt $max ]]; then
                echo "pip install failed (attempt $n/$max). Retrying in $delay seconds..."
                sleep $delay
                ((n++))
            else
                echo "pip install failed after $max attempts. Exiting."
                exit 1
            fi
        }
    done
}

sudo apt clean
sudo update-initramfs -u -k all
sudo dpkg --configure -a
sudo apt update -y
sudo apt install -y chromium-browser chromium-chromedriver sox libsox-fmt-all portaudio19-dev espeak-ng --fix-missing
sudo apt install -y xterm libcap-dev --fix-missing
chromium-browser --version
chromedriver --version
sox --version

cd src
python3 -m venv .venv --system-site-packages

if [ -f ".venv/bin/activate" ]; then
    source .venv/bin/activate
else
    echo "Error: Virtual environment activation script not found!"
    exit 1
fi

sudo chown -R $(id -u):$(id -g) .venv/

# Remove system-wide installations to avoid conflicts
echo "Removing system-wide installations of simplejpeg and picamera2..."
sudo apt remove -y python3-simplejpeg python3-picamera2 || true

pip install --upgrade pip

pip uninstall -y numpy simplejpeg picamera2 || true
pip install --no-cache-dir numpy==2.1 simplejpeg picamera2
retry_pip_install

# Copy configuration files if they do not exist
if [ ! -f "config.ini" ]; then
    cp config.ini.template config.ini
    sudo chown $(id -u):$(id -g) config.ini
    sudo chmod 644 config.ini
    echo "Default config.ini created. Please edit it with necessary values."
fi

if [ ! -f "../.env" ]; then
    cp ../.env.template ../.env
    sudo chown $(id -u):$(id -g) ../.env
    sudo chmod 644 ../.env
    echo "Default .env created. Please edit it with necessary values."
fi

export DISPLAY=:0
echo "DISPLAY set to $DISPLAY"
cd ..
sudo chown -R $(whoami):$(whoami) src/
chmod -R 755 src/
echo "Installation completed successfully!"