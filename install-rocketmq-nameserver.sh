#!/bin/bash
# rocketmq版本号
echo "请输入rocketmq版本号:(5.2.0)"
read version
if [ -z "$version" ]; then
  version="5.2.0"
fi
echo "你输入的rocketmq版本号值为:$version"
echo "开始下载并安装rocketmq"
sudo wget -c https://dist.apache.org/repos/dist/release/rocketmq/$version/rocketmq-all-$version-bin-release.zip
sudo unzip rocketmq-all-$version-bin-release.zip
sudo mv rocketmq-all-$version-bin-release /usr/local/rocketmq
sudo chown -R ec2-user:ec2-user /usr/local/rocketmq/
echo "rocketmq安装完毕"

echo "配置内容"
echo "请输入cpu:(4)"
read cpu
if [ -z "$cpu" ]; then
  cpu="4"
fi
echo "你输入的cpu值为:$cpu"
echo "请输入内存:(4)g"
read memory
if [ -z "$memory" ]; then
  memory="4"
fi
echo "你输入的内存值为:$memory"
sed -i "s/Xms4g/Xms${cpu}g/g" /usr/local/rocketmq/bin/runserver.sh
sed -i "s/Xmx4g/Xms${memory}g/g" /usr/local/rocketmq/bin/runserver.sh

echo "开始写入启动文件rocketmqname.service"
startConf="
[Unit]
Description=rocketmq-nameservern
Documentation=http://mirror.bit.edu.cn/apache/rocketmq/
After=network.target

[Service]
Type=sample
User=ec2-user
ExecStart=/usr/local/rocketmq/bin/mqnamesrv
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s QUIT $MAINPID
Restart=0
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target"
echo -e $startConf |sudo tee -a /lib/systemd/system/rocketmqname.service >/dev/null

# 启动
sudo systemctl start rocketmqname
sudo systemctl enable rocketmqname
