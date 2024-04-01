#!/bin/bash
# rocketmq版本号
echo "请输入rocketmq版本号:(5.2.0)"
read version
if [ -z "$version" ]; then
  version="5.2.0"
fi
echo "你输入的rocketmq版本号值为:$version"
# 集群号
echo "请输入集群号:(0)"
read num
if [ -z "$num" ]; then
  num="0"
fi
echo "你输入的集群号值为:$num"
# 端口号
echo "请输入端口:(30911)"
read port
if [ -z "$port" ]; then
  port="30911"
fi
echo "你输入的端口值为:$port"
# namerserver地址
echo "请输入nameServer:地址:端口，以;隔开:(127.0.0.1:9876)"
read namesrvAddr
if [ -z "$namesrvAddr" ]; then
  namesrvAddr="127.0.0.1:9876"
fi
echo "请输入nameServer地址:$namesrvAddr"
# borker地址集群
echo "请输入borker地址集群:地址:端口，以;隔开:"
newDLegerPeers=""
read dLegerPeers
# 使用IFS（内部字段分隔符）来split字符串
IFS=';' read -ra ADDR <<< "$dLegerPeers"
# 获取长度
length=`expr ${#ADDR[@]} - 1`
for index in ${!ADDR[@]}
do
  # 使用cut获取字符
  item=${ADDR[$index]}
  newDLegerPeers+="n$index-$item"
  if [ $index -lt $length ]; then
  	newDLegerPeers+=";"
  fi
done
IFS=' '
echo "请输入nameServer地址:$newDLegerPeers"
# 配置内容
borkerConf="## 集群名
brokerClusterName = RaftCluster
## broker组名，同一个RaftClusterGroup内，brokerName名要一样
brokerName=RaftNode00
## 监听的端口
listenPort=$port
## 设置的NameServer地址和端口
namesrvAddr=$namesrvAddr
storePathRootDir=/tmp/rmqstore/node0${num}
storePathCommitLog=/tmp/rmqstore/node0${num}/commitlog
enableDLegerCommitLog=true
dLegerGroup=RaftNode00
dLegerPeers=$newDLegerPeers
dLegerSelfId=n0
deleteWhen=04
fileReservedTime = 48
brokerRole = ASYNC_MASTER
flushDiskType = SYNC_FLUSH
messageDelayLevel = 1s 5s 10s 30s 1m 2m 3m 4m 5m 6m 7m 8m 9m 10m 20m 30m 1h 2h
sendMessageThreadPoolNums = 6
useReentrantLockWhenPutMessage = true
waitTimeMillsInSendQueue = 250
retryAnotherBrokerWhenNotStoreOK = true
storePathRootDir = /home/ec2-user/store"

echo "开始下载并安装rocketmq"
sudo wget -c https://dist.apache.org/repos/dist/release/rocketmq/$version/rocketmq-all-$version-bin-release.zip
sudo unzip rocketmq-all-$version-bin-release.zip
sudo mv rocketmq-all-$version-bin-release /usr/local/rocketmq
sudo chown -R ec2-user:ec2-user /usr/local/rocketmq/
echo $borkerConf > "/usr/local/rocketmq/conf/dledger/broker-n${num}.conf"
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
sed -i "s/Xms8g/Xms${cpu}g/g" /usr/local/rocketmq/bin/runbroker.sh
sed -i "s/Xmx8g/Xms${memory}g/g" /usr/local/rocketmq/bin/runbroker.sh

echo "开始写入启动文件rocketmqbroker.service"
startConf="
[Unit]
Description=rocketmq-broker
Documentation=http://mirror.bit.edu.cn/apache/rocketmq/
After=network.target

[Service]
Type=sample
User=ec2-user
ExecStart=/usr/local/rocketmq/bin/mqbroker -c /usr/local/rocketmq/conf/dledger/broker-n${num}.conf
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s QUIT $MAINPID
Restart=0
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target"
echo $startConf |sudo tee -a /lib/systemd/system/rocketmqbroker.service >/dev/null

# 启动
sudo systemctl start rocketmqbroker
sudo systemctl enable rocketmqbroker
