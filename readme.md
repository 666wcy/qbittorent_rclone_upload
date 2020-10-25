### qBittorrent v4.3.0.1



内装rclone世纪互联版

内封上传脚本

[上传脚本来源](https://www.hostloc.com/thread-612238-1-1.html )

loc大佬牛逼!!

运行docker

```shell
docker run  --name qbittorrent -d \
-p 6881:6881 \
-p 6881:6881/udp \
-p 8080:8080 \
-v /root/qbittorrent/config:/config \
-v /root/qbittorrent/downloads:/downloads \
-v /root/qbittorrent/upload:/upload \
--restart=always \
/benchao/qbittorrent-rclone:v1.4

```

docker中的-v映射地址可以自行修改



## rclone配置

在config文件夹下新建文件夹**rclone**，放入自己的**rclone.conf**配置文件



## 自动上传文件配置

编辑upload文件夹下的qb_auto.sh文件![]()

```
the_dir="${save_dir//\/downloads\//}"	#如果你修改了主下载地址，请修改这里

qb_version="4.3.0.1"	#qb版本
qb_username="admin"		#qb用户名
qb_password="adminadmin"	#qb密码
qb_web_url="http://localhost:8080"	#qb的web地址
leeching_mode="true"	#这个不用管
log_dir="/config/log"	#需要打印的日志地址
rclone_dest="yun"		#需要上传的rclone驱动器名称
rclone_parallel="32"	#rclone上传线程
auto_del_flag="test"	#上传完成后将种子改变的分类名
```

默认上传后不删除文件，如果需要删除，将sh中所有的**#qb_del**的#号删除



## qb命令配置

设置 **Torrent 完成时运行外部程序**

```shell
bash /upload/qb_auto.sh  "%N" "%F" "%R" "%D" "%C" "%Z" "%I"
```





## 效果展示

![qb配置](https://github.com/666wcy/qbittorent_rclone_upload/raw/main/qb.png)

![上传日志](https://github.com/666wcy/qbittorent_rclone_upload/raw/main/log.png)

![上传内容](https://github.com/666wcy/qbittorent_rclone_upload/raw/main/upload.png)

