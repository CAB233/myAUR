## 使用方法

导入我的公钥

```bash
pacman-key --init
pacman-key --recv-key 62FFE3FEF4158CF1 --keyserver keys.openpgp.org
pacman-key --lsign-key 62FFE3FEF4158CF1
```

在 /etc/pacman.conf 中加入

```bash
[zuoye-aur]
Server = https://repo.zuoye.win/archlinux/repo/x86_64
```

刷新数据库
```bash
pacman -Syy
```
