#!/bin/bash
sudo apt-get update && upgrade -y
sudo apt-get install libsnappy-dev libc6-dev libc6 unzip build-essential git -y
cd ~
curl -LO https://github.com/NethermindEth/nethermind/releases/download/1.15.0/nethermind-linux-amd64-1.15.0-2b70876-20221228.zip
unzip nethermind-linux-amd64-1.15.0-2b70876-20221228.zip -d nethermind
sudo cp -a nethermind /usr/local/bin/nethermind
sudo rm nethermind-linux-amd64-1.15.0-2b70876-20221228.zip
sudo rm -r nethermind
sudo useradd --no-create-home --shell /bin/false nethermind
sudo mkdir -p /var/lib/nethermind
sudo chown -R nethermind:nethermind /var/lib/nethermind
sudo chown -R nethermind:nethermind /usr/local/bin/nethermind
sudo mkdir -p /var/lib/jwtsecret/nethermind
openssl rand -hex 32 | sudo tee -a /var/lib/jwtsecret/jwt.hex > /dev/null



curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee -a /etc/apt/sources.list.d/yarn.list > /dev/null
sudo apt update -y && sudo apt install yarn -y
curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash -
sudo apt-get install -y nodejs

git clone https://github.com/chainsafe/lodestar.git
cd lodestar
yarn install --ignore-optional
yarn run build
cd ~
sudo cp -a lodestar /usr/local/bin
sudo rm -r lodestar
sudo useradd --no-create-home --shell /bin/false lodestarbeacon
sudo mkdir -p /var/lib/lodestar/beacon
sudo chown -R lodestarbeacon:lodestarbeacon /var/lib/lodestar/beacon

echo "[Unit]
Description=Lodestar Consensus Beacon Client (Gnosis)
Wants=network-online.target
After=network-online.target
[Service]
User=lodestarbeacon
Group=lodestarbeacon
Type=simple
Restart=always
RestartSec=5
WorkingDirectory=/usr/local/bin/lodestar
ExecStart=/usr/local/bin/lodestar/lodestar beacon \
  --network gnosis \
  --dataDir /var/lib/lodestar/beacon \
  --execution.urls http://127.0.0.1:8551 \
  --checkpointSyncUrl https://checkpoint.gnosischain.com \
  --jwt-secret /var/lib/jwtsecret/jwt.hex
[Install]
WantedBy=multi-user.target" | sudo tee -a /etc/systemd/system/lodestarbeacon.service > /dev/null

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
  --JsonRpc.JwtSecretFile=/var/lib/jwtsecret/jwt.hex \
  --Metrics.Enabled true \
  --TraceStore.Enabled true \
  --TraceStore.BlocksToKeep 0 \
  --Metrics.ExposePort 6969 \
  --JsonRpc.Enabled true \
  --JsonRpc.Timeout 20000 \
  --JsonRpc.Host 127.0.0.1 \
  --JsonRpc.Port 9545 \
  --JsonRpc.EnabledModules Eth,Trace,TxPool,Web3,Personal,Proof,Net,Parity,Health,Rpc
[Install]
WantedBy=default.target" | sudo tee /etc/systemd/system/nethermind.service > /dev/null

sudo systemctl daemon-reload
sudo systemctl start nethermind
sudo systemctl enable nethermind
