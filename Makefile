PREFIX := /usr/local

.PHONY: install

orobas:
	cat cli/src/header.bash cli/src/functions.bash cli/src/main.bash > orobas.sh
	chmod 755 orobas.sh

install: orobas
	cp orobas.sh $(PREFIX)/bin/orobas
	rm orobas.sh

	mkdir -p /etc/qemu /etc/systemd/scripts
	cp etc/qemu/bridge.conf /etc/qemu/bridge.conf
	cp etc/systemd/scripts/qemu-network-env /etc/systemd/scripts/
	cp etc/systemd/system/qemu-network-env.service /etc/systemd/system/

	systemctl daemon-reload
	systemctl start qemu-network-env
	systemctl enable qemu-network-env
