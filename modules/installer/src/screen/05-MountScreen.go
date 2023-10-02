package screen

import (
	"ghaf-installer/global"

	"github.com/pterm/pterm"
)

// Method to get the heading message of screen
func (m ScreensMethods) MountScreenHeading() string {
	return "Select partitions and install"
}

func (m ScreensMethods) MountScreen() {

	ghafMountingSpinner, _ := pterm.DefaultSpinner.
		WithShowTimer(false).
		WithRemoveWhenDone(true).
		Start("Mounting Partition")

	mountGhaf("/dev/" + selectedPartition)

	ghafMountingSpinner.Stop()

	pterm.Info.Printfln("Ghaf has been mounted to /boot and /root")
	goToNextScreen()
	return
}

func mountGhaf(disk string) {
	_, err := global.ExecCommand("mkdir", "-p", "/home/ghaf/root")
	if err != 0 {
		panic(err)
	}

	_, err = global.ExecCommand("sudo", "mount", disk+"p2", "/home/ghaf/root")
	if err != 0 {
		panic(err)
	}
}
