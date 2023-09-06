package screen

import (
	"ghaf-installer/global"

	"github.com/pterm/pterm"
	//"unicode/utf8"
)

func ExitScreen() {
	exit := []string{
		previousScreenMsg,
		"Reboot",
		"Shutdown",
		"Close installer",
	}
	selectedExitOption, _ := pterm.DefaultInteractiveSelect.
		WithOptions(exit).
		Show("Please select command to do next")

	if checkSkipScreen(selectedExitOption) {
		return
	}

	if selectedExitOption == "Reboot" {
		global.ExecCommand("sudo", "reboot")
	} else if selectedExitOption == "Shutdown" {
		global.ExecCommand("sudo", "shutdown", "00:01")
	}

	goToNextScreen()

}
