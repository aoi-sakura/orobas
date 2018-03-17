#!/usr/bin/env bats

load _loader

@test "generate mac address" {
      ar "image" "title" "test"
      result="$(generate_mac_addr_from_title)"
      [ ${result} == "52:54:37:bf:48:af" ]
}

@test "normal parse subcommand" {
      parse_subcommand "create"
      [ "$subcommand" == "create" ]
}

@test "filepath parse subcommand" {
      ar "system" "vm_store" "$HOME/.local/share/orobas"
      parse_subcommand "ubuntu_normal__c2_m1024_M5254179abd57.qcow2"
      result=$(ar "image" "path")
      [ "$result" == "ubuntu_normal__c2_m1024_M5254179abd57.qcow2" ]
}