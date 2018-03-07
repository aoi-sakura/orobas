PREFIX := /usr/local

.PHONY: install

install:
	cat cli/src/header.bash cli/src/functions.bash cli/src/main.bash > __orobas.sh
	chmod 755 __orobas.sh
	cp __orobas.sh $(PREFIX)/bin/orobas
	rm __orobas.sh

	mkdir -p /etc/qemu /etc/systemd/scripts
	cp etc/qemu/bridge.conf /etc/qemu/bridge.conf
	cp etc/systemd/scripts/qemu-network-env /etc/systemd/scripts/
	cp etc/systemd/system/qemu-network-env.service /etc/systemd/system/

	systemctl daemon-reload
	systemctl start qemu-network-env
	systemctl enable qemu-network-env
