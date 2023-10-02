package screen

import (
	"ghaf-installer/global"
)

var registrationAgentScript = "./script/registration-agent-laptop"

// Method to get the heading message of screen
func (m ScreensMethods) RegistrationAgentHeading() string {
	return "Registration Agent"
}

func (m ScreensMethods) RegistrationAgent() {
	global.ExecCommandWithLiveMessage(registrationAgentScript)

	goToNextScreen()

}
