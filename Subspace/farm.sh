#!/bin/sh
sudo su
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
sudo apt update 

### 
cd /home/ubuntu
wget https://github.com/subspace/subspace/releases/download/snapshot-2022-mar-09/subspace-node-ubuntu-x86_64-snapshot-2022-mar-09
wget https://github.com/subspace/subspace/releases/download/snapshot-2022-mar-09/subspace-farmer-ubuntu-x86_64-snapshot-2022-mar-09
wget https://github.com/subspace/subspace/releases/download/snapshot-2022-mar-09/chain-spec-snapshot-2022-mar-09.json

chmod +x subspace-farmer-ubuntu-x86_64-snapshot-2022-mar-09
chmod +x subspace-node-ubuntu-x86_64-snapshot-2022-mar-09

mv subspace-farmer-ubuntu-x86_64-snapshot-2022-mar-09 subspace-farmer
mv subspace-node-ubuntu-x86_64-snapshot-2022-mar-09 subspace-node

## Node
sudo tee <<EOF >/dev/null /etc/systemd/system/subnode.service
[Unit]
  Description=Subspace Node
  After=network-online.target
[Service]
  User=root
  ExecStart=/home/ubuntu/subspace-node \
  --chain testnet \
  --wasm-execution compiled \
  --execution wasm \
  --bootnodes "/dns/farm-rpc.subspace.network/tcp/30333/p2p/12D3KooWPjMZuSYj35ehced2MTJFf95upwpHKgKUrFRfHwohzJXr" \
  --rpc-cors all \
  --rpc-methods unsafe \
  --ws-external \
  --validator \
  --telemetry-url "wss://telemetry.polkadot.io/submit/ 1" \
  --telemetry-url "wss://telemetry.subspace.network/submit/ 1" \
  --name $(($RANDOM%1000))
  Restart=on-failure
  RestartSec=10
  LimitNOFILE=65535
[Install]
  WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable subnode
sudo systemctl restart subnode
# journalctl -fu subnode

## Farm
sudo tee <<EOF >/dev/null /etc/systemd/system/farmer.service
[Unit]
  Description=Subspace Farmer
  After=network-online.target
[Service]
  User=root
  ExecStart=/home/ubuntu/subspace-farmer farm --reward-address st9XWcQiURQV38tMwA55wWEAQWmjK8C3ri2gMbBVrJMkf7gWG
  Restart=on-failure
  RestartSec=10
  LimitNOFILE=65535
[Install]
  WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable farmer
sudo systemctl restart farmer

