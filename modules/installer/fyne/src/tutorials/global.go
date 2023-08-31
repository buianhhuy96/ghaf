package tutorials

import ()
 
var selectedPartition string
var selectedWifi string
var installGhaf = false
var ghaf = "/home/huy/ghaf/result/iso/nixos-23.05.20230711.8163a64-x86_64-linux.iso"


func selectPartition(partition string) {
	selectedPartition = partition
}

func getGhaf() string {
	return ghaf
}

func checkGhafInstalled() bool {
	return installGhaf
}

func setGhafInstalled(installed bool)  {
	installGhaf = installed
}