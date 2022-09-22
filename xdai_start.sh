#!/bin/bash
sudo apt-get update && upgrade -y
sudo apt-get install libsnappy-dev libc6-dev libc6 unzip -y
cd ~
curl -LO https://github.com/NethermindEth/nethermind/releases/download/1.14.1/nethermind-linux-amd64-1.14.1-1a32d45-20220907.zip
unzip nethermind-linux-amd64-1.14.1-1a32d45-20220907.zip -d nethermind
sudo cp -a nethermind /usr/local/bin/nethermind
rm nethermind-linux-amd64-1.14.1-1a32d45-20220907.zip
rm -r nethermind
sudo useradd --no-create-home --shell /bin/false nethermind
sudo mkdir -p /var/lib/nethermind
sudo chown -R nethermind:nethermind /var/lib/nethermind
sudo chown -R nethermind:nethermind /usr/local/bin/nethermind
sudo mkdir -p /var/lib/jwtsecret/nethermind
openssl rand -hex 32 | sudo tee /var/lib/jwtsecret/nethermind/jwt.hex > /dev/null

echo "[Unit]
Description=Nethermind Execution Client (Gnosis)
After=network.target
Wants=network.target
[Service]
User=nethermind
Group=nethermind
Type=simple
Restart=always
RestartSec=5
WorkingDirectory=/var/lib/nethermind
Environment="DOTNET_BUNDLE_EXTRACT_BASE_DIR=/var/lib/nethermind"
ExecStart=/usr/local/bin/nethermind/Nethermind.Runner \
  --config /usr/local/bin/nethermind/configs/xdai_archive.cfg \
  --datadir /var/lib/nethermind \
  --JsonRpc.JwtSecretFile=/var/lib/jwtsecret/nethermind/jwt.hex \
  --Metrics.Enabled true \
  --Metrics.ExposePort 6969 \
  --JsonRpc.Enabled true \
  --JsonRpc.Timeout 20000 \
  --JsonRpc.Host 127.0.0.1 \
  --JsonRpc.Port 9545 \
  --JsonRpc.EnabledModules Eth,Trace,TxPool,Web3,Personal,Proof,Net,Parity,Health,Rpc
[Install]
WantedBy=default.target" >> /etc/systemd/system/nethermind.service \

sudo systemctl daemon-reload
sudo systemctl start nethermind
sudo systemctl enable nethermind
