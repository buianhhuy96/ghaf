package screen

import (
	"ghaf-installer/global"
	"time"

	"github.com/pterm/pterm"
)

// Path to registration-agent-laptop binary
var registrationAgentScript = "./script/registration-agent-laptop"

// Environment variables required for registration-agent-laptop
var certPath = "/var/fogdata/certs"
var configPath = "/var/fogdata/config"
var tokenPath = "/var/fogdata/token"

// Method to get the heading message of screen
func (m ScreensMethods) RegistrationAgentHeading() string {
	return "Registration Agent"
}

func (m ScreensMethods) RegistrationAgent() {

	if !(haveMountedSystem) {
		pterm.Error.Printfln("No system has been mounted")
		goToScreen(GetCurrentScreen() + 1)
		return
	}
	// Set create folders to store certificates
	prepareEnvironment()

	// Execute registration-agent-laptop binary
	global.ExecCommandWithLiveMessage("bash", registrationAgentScript)

	// Set permission of the certificates
	//setPermission()

	// Wait for 3 seconds for user to read the finish log
	time.Sleep(3)
	goToScreen(GetCurrentScreen() + 1)

}

func prepareEnvironment() {
	// Create folder for certificates and config
	_, err := global.ExecCommand("sudo", "mkdir", "-p", certPath)
	if err != 0 {
		panic(err)
	}

	_, err = global.ExecCommand("sudo", "mkdir", "-p", configPath)
	if err != 0 {
		panic(err)
	}

	_, err = global.ExecCommand("sudo", "mkdir", "-p", tokenPath)
	if err != 0 {
		panic(err)
	}
}

func setPermission() {

	_, err := global.ExecCommand("sudo", "chmod", "-R", "777", certPath)
	if err != 0 {
		panic(err)
	}
	_, err = global.ExecCommand("sudo", "chmod", "-R", "777", configPath)
	if err != 0 {
		panic(err)
	}
	_, err = global.ExecCommand("sudo", "chmod", "-R", "777", tokenPath)
	if err != 0 {
		panic(err)
	}
}
