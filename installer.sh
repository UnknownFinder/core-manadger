#!/bin/bash
work_dir=$(pwd)
echo "[Unit]" >> /etc/systemd/system/task-manager.service
echo "Description=daemon to manage core load" >> /etc/systemd/system/task-manager.service
echo "After=network.target" >> /etc/systemd/system/task-manager.service
echo "[Service]" >> /etc/systemd/system/task-manager.service
echo "ExecStart=/$work_dir/task-manager.sh" >> /etc/systemd/system/task-manager.service
echo "Restart=on-failure" >> /etc/systemd/system/task-manager.service
echo "[Install]" >> /etc/systemd/system/task-manager.service
echo "WantedBy=multi-user.target" >> /etc/systemd/system/task-manager.service
sleep 1
sudo systemctl enable task-manager.service
sudo systemctl start task-manager.service
sudo systemctl daemon-reload
sleep 5
echo "Daemon to manage cores load is available. Have a nice day, $USER"
