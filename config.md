# 系统字体设置
如果用的时fcitx4的话：
```bash

```
如果用的输入法不是fcitx4，如fcitx5、ibus：

# 改键

```bash
cp dotfiles/hwdb/01-personal-kbd.hwdb
udevadm hwdb --update
udevadm trigger
```


# 解决 lightdm 启动问题

修改/etc/lightdm/lightdm.conf

将里面的logind-check-graphical修改为true

