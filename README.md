[![Packages CI(full)](https://github.com/CAB233/myAUR/actions/workflows/build-full.yml/badge.svg)](https://github.com/CAB233/myAUR/actions/workflows/build-full.yml) [![Packages CI(part)](https://github.com/CAB233/myAUR/actions/workflows/build-part.yml/badge.svg)](https://github.com/CAB233/myAUR/actions/workflows/build-part.yml)

### 使用方法

导入我的公钥

```bash
pacman-key --init
pacman-key --recv-key 62FFE3FEF4158CF1 --keyserver keys.openpgp.org
pacman-key --lsign-key 62FFE3FEF4158CF1
```

在 /etc/pacman.conf 中加入

```bash
[zuoye-aur]
Server = https://repo.zuoye.win/archlinux/x86_64
```

刷新数据库
```bash
pacman -Syy
```
