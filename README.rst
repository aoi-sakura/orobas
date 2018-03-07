========
Orobas
========

qemu の VM を管理するための script、及びサーバ設定、ansible の playbook

名称は `オロバス - Wikipedia <https://ja.wikipedia.org/wiki/%E3%82%AA%E3%83%AD%E3%83%90%E3%82%B9>`_ より

virt-manager を使うまでもない、だけど qemu コマンドをそのまま打つのは option 多すぎて大変なので、コマンド option をまとめておく程度の管理を目指す。
また、virt-manager だと bridge 接続に root が必要だったり、libvirt は xml で設定書くのが辛い...、というのも作った理由。

  - 個人の開発・検証用途
  - 薄い wrapper 程度の層に留める


構成
------

| orobos
| ├ cli
| ├ etc
| │ └ systemd
| │ 　 ├ scripts
| │ 　 └ system
| └ ansible
| 　 ├ vars
| 　 └ roles


事前にインストールされているべきもの
---------------------------------------

* app-emulation/qemu
* net-dns/dnsmasq
* net-misc/bridge-utils
* net-firewall/iptables

* kernel configuration

    CONFIG_MACVLAN=<y or m>
    CONFIG_MACVTAP=<y or m>
    CONFIG_VXLAN=<y or m>
    CONFIG_TUN=<y or m>
    CONFIG_TAP=<y or m>


インストール
--------------

下記を実行することで cli 以下の .sh を .sh を削って /usr/local/bin へ、lib は /usr/local/lib へ、etc の中身を /etc へ展開する

    % cd orobos
    % sudo make install


下記で ansible を ~/.local/orobos/ansible に、config を ~/.config/orobos に symlink、~/.local/orobos/VMs を VM 格納先にする

    % cd orobos
    % make user-install
