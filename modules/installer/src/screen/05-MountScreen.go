package screen

import (
	"time"

	"github.com/pterm/pterm"
)

// Method to get the heading message of screen
func (m ScreensMethods) MountScreenHeading() string {
	return "Mount partition for configuring"
}

func (m ScreensMethods) MountScreen() {

	if !(haveInstalledSystem) {
		goToNextScreen()
		return
	}

	ghafMountingSpinner, _ := pterm.DefaultSpinner.
		WithShowTimer(false).
		WithRemoveWhenDone(true).
		Start("Mounting Partition")

	// Mount ghaf system
	mountGhaf("/dev/" + selectedPartition)

	// Wait time for user to read the message
	time.Sleep(2)
	ghafMountingSpinner.Stop()

	pterm.Info.Printfln("Ghaf has been mounted to /root")

	time.Sleep(1)
	goToNextScreen()
	return
}
