### 使用方法

导入我的公钥

```undefined
pacman-key --init
pacman-key --recv-key 62FFE3FEF4158CF1 --keyserver keys.openpgp.org
pacman-key --lsign-key 62FFE3FEF4158CF1
```

在 /etc/pacman.conf 中加入

```undefined
[zuoye-aur]
Server = https://repo.zuoye.win/archlinux/$arch
```
