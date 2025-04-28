#!/bin/bash

# Update system
sudo apt-get update
sudo apt-get upgrade -y

# Install Dart
sudo apt-get install apt-transport-https
sudo sh -c 'wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -'
sudo sh -c 'wget -qO- https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list'
sudo apt-get update
sudo apt-get install dart

# Install Nginx
sudo apt-get install nginx -y

# Configure Nginx as reverse proxy
sudo tee /etc/nginx/sites-available/connect4 << EOF
server {
    listen 80;
    server_name your-domain.com;  # Replace with your domain

    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

# Enable the site
sudo ln -s /etc/nginx/sites-available/connect4 /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

# Install Certbot for SSL
sudo apt-get install certbot python3-certbot-nginx -y
sudo certbot --nginx -d your-domain.com  # Replace with your domain

# Create server directory
mkdir -p ~/connect4-server
cd ~/connect4-server

# Copy server files
# Note: You'll need to copy your server.dart and pubspec.yaml files here

# Install dependencies
dart pub get

# Create SSL certificate directory
mkdir -p ~/connect4-server/certs
sudo cp /etc/letsencrypt/live/your-domain.com/fullchain.pem ~/connect4-server/certs/cert.pem
sudo cp /etc/letsencrypt/live/your-domain.com/privkey.pem ~/connect4-server/certs/key.pem
sudo chown -R $USER:$USER ~/connect4-server/certs

# Create systemd service
sudo tee /etc/systemd/system/connect4.service << EOF
[Unit]
Description=Connect4 Game Server
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$HOME/connect4-server
ExecStart=/usr/bin/dart run server.dart
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
sudo systemctl enable connect4
sudo systemctl start connect4

# Create certificate renewal script
sudo tee /etc/cron.daily/renew-connect4-certs << EOF
#!/bin/bash
certbot renew --quiet
cp /etc/letsencrypt/live/your-domain.com/fullchain.pem ~/connect4-server/certs/cert.pem
cp /etc/letsencrypt/live/your-domain.com/privkey.pem ~/connect4-server/certs/key.pem
chown -R $USER:$USER ~/connect4-server/certs
systemctl restart connect4
EOF

sudo chmod +x /etc/cron.daily/renew-connect4-certs

echo "Server deployment complete!"
echo "Check status with: sudo systemctl status connect4"
echo "View logs with: journalctl -u connect4 -f" 