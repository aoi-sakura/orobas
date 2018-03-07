#!/usr/bin/env bats

load _loader

@test "generate mac address" {
      image_conf["title"]="test"
      system_conf["macaddr_prefix"]="52:54:"
      result="$(generate_mac_addr_from_title)"
      [ ${result} == "52:54:37:bf:48:af" ]
}

@test "normal parse subcommand" {
      parse_subcommand "create"
      [ "$subcommand" == "create" ]
}

@test "filepath parse subcommand" {
      system_conf["vm_store"]="$HOME/.local/share/orobas"
      parse_subcommand "ubuntu_normal__c2_m1024_M5254179abd57.qcow2"
      result=${image_conf["path"]}
      [ "$result" == "ubuntu_normal__c2_m1024_M5254179abd57.qcow2" ]
}