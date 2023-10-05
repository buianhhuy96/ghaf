package screen

import (
	"ghaf-installer/global"
	"os"

	"github.com/pterm/pterm"
)

// Method to get the heading message of screen
func (m ScreensMethods) ExitScreenHeading() string {
	return "Installation Complete"
}

func (m ScreensMethods) ExitScreen() {

	// Create and print option list to exit installer
	exit := []string{
		previousScreenMsg,
		"Reboot",
		"Shutdown",
		"Close installer",
		"Unmount system and close installer",
	}
	selectedExitOption, _ := pterm.DefaultInteractiveSelect.
		WithOptions(exit).
		Show("Please select command to do next")

	// If skip option is selected
	if checkSkipScreen(selectedExitOption) {
		return
	}

	// If other options are selected
	if selectedExitOption == "Reboot" {
		global.ExecCommand("sudo", "reboot")
	} else if selectedExitOption == "Shutdown" {
		global.ExecCommand("sudo", "poweroff")
	} else if selectedExitOption == "Close installer" {
		os.Exit(0)
	} else {
		// Unmount ghaf partition
		umountGhaf()
		os.Exit(0)
	}

}
