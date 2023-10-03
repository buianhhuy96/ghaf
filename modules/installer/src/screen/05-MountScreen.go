package screen

import (
	"ghaf-installer/global"
	"time"

	"github.com/pterm/pterm"
)

// Method to get the heading message of screen
func (m ScreensMethods) MountScreenHeading() string {
	return "Mount partition for configuring"
}

func (m ScreensMethods) MountScreen() {

	if selectedPartition == "" {
		goToNextScreen()
		return
	}

	ghafMountingSpinner, _ := pterm.DefaultSpinner.
		WithShowTimer(false).
		WithRemoveWhenDone(true).
		Start("Mounting Partition")

	mountGhaf("/dev/" + selectedPartition)

	time.Sleep(2)
	ghafMountingSpinner.Stop()

	pterm.Info.Printfln("Ghaf has been mounted to /root")

	goToNextScreen()
	return
}

func mountGhaf(disk string) {
	_, err := global.ExecCommand("mkdir", "-p", mountPoint)
	if err != 0 {
		panic(err)
	}

	_, err = global.ExecCommand("sudo", "mount", disk+"p2", mountPoint)
	if err != 0 {
		panic(err)
	}
}
