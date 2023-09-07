package screen

import (
	"ghaf-installer/global"
	"os"

	"github.com/pterm/pterm"
	//"unicode/utf8"
)

func ExitScreen() {
	// Create and print option list to exit installer
	exit := []string{
		previousScreenMsg,
		"Reboot",
		"Shutdown",
		"Close installer",
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
	} else {
		os.Exit(0)
	}

}
