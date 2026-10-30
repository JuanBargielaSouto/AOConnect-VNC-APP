# AOTECH Remote Access

A cross-platform application developed with Flutter for managing and remotely accessing AOTECH devices. It allows users to remotely view and control devices connected to optical sensors using VNC technology.

The solution consists of a Flutter client application and a Node.js-based backend server, together with noVNC and TigerVNC to provide remote desktop access to the devices.

## 1. Technologies Used

- **Flutter / Dart:** cross-platform application development (Windows and Android).
- **Node.js / Express:** backend server and REST API implementation.
- **SQLite:** storage of users, devices and device assignments.
- **noVNC:** remote desktop access through a web browser.
- **TigerVNC:** VNC server used to share the device's desktop.
- **TailScale** VPN app to secure and allow the connections between devices.
- **systemd:** automation of service startup on Raspberry Pi devices.

## 2. Flutter Application Installation

### 2.1. Prerequisites

The following software is required:

- Android Studio.
- Flutter SDK.
- Dart SDK (included with Flutter).
- Git.

### 2.2. Downloading and Opening the Project

1. Download or clone the GitHub repository.
2. Open Android Studio.
3. Select **Open** and choose the project's root directory.
4. Wait for Android Studio to recognize the Flutter project.
5. Open a terminal in the project root directory and run:

```bash
flutter pub get
```

This command installs the dependencies defined in `pubspec.yaml`.

### 2.3. Creating the .env Configuration File

Inside the `AOConnect` directory, create a file named `.env`. This file contains the connection parameters for the backend server and noVNC. You can adapt the parameters in the configuration example below.

Example configuration:

```env
DEVICE_IP=10.0.0.1
APP_PORT=6080
DATABASE_PORT=3000
```

Parameter descriptions:

| Parameter | Description |
|---|---|
| `DEVICE_IP` | IP address of the device running the Node.js backend server. |
| `APP_PORT` | noVNC listening port. In this example, 6080. It must match the port configured on each device running noVNC. |
| `DATABASE_PORT` | Node.js backend server listening port. In this example, 3000. |

IP addresses and ports can be changed according to the network configuration of each installation.

**Important:** The `.env` file must follow the `VARIABLE=VALUE` format, without unnecessary spaces.

## 3. VNC Access Configuration on Devices

Each device that needs to be accessed remotely must have noVNC and TigerVNC installed and properly configured.

### 3.1. Installing noVNC and TigerVNC

On Debian-based systems or Raspberry Pi OS, the required components can be installed using:

```bash
sudo apt update
sudo apt install novnc tigervnc-standalone-server tigervnc-tools
```

Python 3 and websockify are also required:

```bash
sudo apt install python3-websockify
```

### 3.2. Configuring noVNC

Once noVNC is installed, the custom `client.html` file included in the repository must be added to the noVNC directory.

Copy this file into the noVNC installation directory, alongside the other HTML client files.

For example:

```text
/usr/share/novnc/
    ├── vnc.html
    ├── client.html
    ├── app/
    ├── core/
    └── ...
```

The `client.html` file provides the VNC connection interface used by the Flutter application.

### 3.3. Manually Starting the Services

To verify that everything works correctly before automating the startup process, the following commands can be executed manually.

**TigerVNC server:**

```bash
x0tigervncserver :0 -rfbport 5901 -SecurityTypes=None
```

This command shares the device's graphical desktop through VNC using port 5901.

**noVNC server:**

```bash
websockify --web=/usr/share/novnc 6080 localhost:5901
```

This command starts the noVNC web server and establishes the communication bridge between WebSocket and the VNC server.

Port 6080 will be used by the Flutter application to access the noVNC service.

## 4. Tailscale Installation and Configuration

Tailscale is used to establish a secure private network between the devices and the Flutter application. It allows remote access to devices without requiring public IP addresses or direct exposure of VNC and backend ports to the Internet.

### 4.1. Installing Tailscale

Tailscale must be installed on every device that will participate in the remote access network, including:

- Each Raspberry Pi or remote device running the VNC and backend services.
- The computer or mobile device running the Flutter application.

Installation instructions for each supported operating system are available on the official website:

https://tailscale.com/download

For Debian-based systems and Raspberry Pi OS, Tailscale can also be installed using its official installation script:

```bash
curl -fsSL https://tailscale.com/install.sh | sh
```

### 4.2. Signing In and Connecting Devices

After installing Tailscale, each device must be authenticated using the same Tailscale network (tailnet).

On each device, run:

```bash
sudo tailscale up
```

Follow the authentication link displayed in the terminal and sign in using the appropriate Tailscale account.

Repeat this process on every device that needs to communicate with the application.

Once authenticated, the devices will be connected to the same private network and will be assigned Tailscale IP addresses.

These IP addresses should be used in the application's connection configuration instead of local network addresses when accessing devices remotely.

### 4.3. Verifying the Connection

To check whether Tailscale is running correctly, execute:

```bash
tailscale status
```

To retrieve the device's Tailscale IP address:

```bash
tailscale ip -4
```

The devices should be able to communicate with each other through their Tailscale IP addresses.

**Important:** All devices must belong to the same authorized Tailscale network, and the account administrator must ensure that the necessary network access permissions are configured.

## 5. Backend Installation and Configuration

### 5.1. Installing Node.js and npm

Node.js and npm must be installed on the device that will run the backend.

Their installation can be verified using:

```bash
node -v
npm -v
```

### 5.2. Installing Dependencies

Create the directory intended for the backend and place the `server.js` file provided in the repository inside it.

From the backend directory, install the required dependencies:

```bash
npm install express sqlite3 bcrypt jsonwebtoken cors dotenv
```

The dependencies used are:

- `express`: HTTP server and REST API implementation.
- `sqlite3`: SQLite database connection and management.
- `bcrypt`: password hashing.
- `jsonwebtoken`: generation and validation of authentication tokens.
- `cors`: configuration of cross-origin access.
- `dotenv`: loading environment variables from `.env` files.

### 5.3. Starting the Backend

Once the dependencies have been installed and the database connection has been configured, run:

```bash
node server.js
```

The server will start listening on the port configured in its source code.

For this example installation, port 3000 will be used.

When lauched the first time, the backend itself will create the database.db and ask for the boss user credentials, which will be name and password. Use those to access the app the first time and start creating more users.

## 6. Automating Startup with systemd

To avoid manually starting the backend, noVNC and TigerVNC every time the Raspberry Pi is restarted, it is recommended to configure `systemd` services.

This allows the services to start automatically when the operating system boots and restart if an unexpected failure occurs.

The following files must be created inside:

```text
/etc/systemd/system/
```

### 6.1. Backend Service: backend.service

Create the file:

```bash
sudo nano /etc/systemd/system/backend.service
```

Contents:

```ini
[Unit]
Description=Backend VNC Node Server
After=network.target

[Service]
Type=simple
User=raspberry
WorkingDirectory=/home/raspberry/AOTECH-VNC-APP-BACKEND/backend-vnc
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=5
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
```

This service automatically starts the Node.js server and allows it to restart if an error occurs.

### 6.2. noVNC Service: novnc.service

Create the file:

```bash
sudo nano /etc/systemd/system/novnc.service
```

Contents:

```ini
[Unit]
Description=noVNC WebSocket Proxy
After=network-online.target x0vncserver.service display-manager.service
Wants=network-online.target x0vncserver.service

[Service]
Type=simple
User=raspberry
WorkingDirectory=/home/raspberry/AOTECH-VNC-APP-BACKEND/noVNC

ExecStartPre=/bin/sleep 10
ExecStart=/usr/bin/python3 /usr/bin/websockify --web /home/raspberry/AOTECH-VNC-APP-BACKEND/noVNC 6080 localhost:5900

Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
```

This service starts noVNC and websockify, allowing WebSocket connections received on port 6080 to be forwarded to the local VNC server.

### 6.3. TigerVNC Service: x0vncserver.service

Create the file:

```bash
sudo nano /etc/systemd/system/x0vncserver.service
```

Contents:

```ini
[Unit]
Description=TigerVNC x0vncserver
After=graphical.target display-manager.service
Wants=graphical.target

[Service]
Type=oneshot
RemainAfterExit=yes
User=raspberry
Environment=DISPLAY=:0
ExecStart=/usr/bin/x0vncserver -display :0 -SecurityTypes None
ExecStop=/usr/bin/killall x0vncserver

[Install]
WantedBy=graphical.target
```

This service allows the Raspberry Pi's graphical desktop to be shared through TigerVNC.

### 6.4. Enabling the Services

Once the three files have been created, reload the systemd configuration:

```bash
sudo systemctl daemon-reload
```

Enable automatic startup:

```bash
sudo systemctl enable backend.service
sudo systemctl enable x0vncserver.service
sudo systemctl enable novnc.service
```

Start the services:

```bash
sudo systemctl start backend.service
sudo systemctl start x0vncserver.service
sudo systemctl start novnc.service
```

To check their status:

```bash
sudo systemctl status backend.service
sudo systemctl status x0vncserver.service
sudo systemctl status novnc.service
```

To view the execution logs of any service:

```bash
sudo journalctl -u backend.service -f
sudo journalctl -u x0vncserver.service -f
sudo journalctl -u novnc.service -f
```

From this point onwards, the services will be configured to start automatically whenever the Raspberry Pi boots.

## 7. Security Recommendations

- Do not publish `.env` files containing credentials or private information.
- Do not use default passwords.
- Do not expose VNC ports directly to the Internet.
- Configure remote access through a private network or VPN.
- Avoid using `SecurityTypes=None` on untrusted networks, as it allows VNC connections without authentication on the local machine.
- Keep Node.js, Flutter and operating system components up to date.

## 8. General System Architecture

The solution architecture is organized as follows:

```text
                 AOTECH Remote Access
                         |
                    Flutter App
                         |
                  HTTP / WebSocket
                         |
                  Raspberry Pi
                         |
             +-----------+-----------+
             |                       |
        Node.js Backend           noVNC
             |                       |
          SQLite                Websockify
                                     |
                                  TigerVNC
                                     |
                              Remote Desktop
```

The Flutter application allows users to authenticate, browse available devices and establish remote connections. The backend manages users, permissions and devices, while noVNC and TigerVNC provide remote desktop access to each device.
