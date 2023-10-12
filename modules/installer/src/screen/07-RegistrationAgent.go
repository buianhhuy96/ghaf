package screen

import (
	"ghaf-installer/global"
	"os"
	"path"
	"path/filepath"
	"time"

	"github.com/pterm/pterm"
)

// Path to registration-agent-laptop binary
var registrationAgentScript = "./script/registration-agent-laptop"
var envFile = "/home/ghaf/.env"

// Environment variables required for registration-agent-laptop
var certPath = mountPoint + "/home/ghaf/certs"
var configPath = mountPoint + "/home/ghaf/config"
var wirelessDevice = interfacesFromSysfs()
var registrationEnv = map[string]string{
	"REGISTRATION_AGENT_PROVISIONING_URL":                "http://localhost:80/api/devices/provision",
	"REGISTRATION_AGENT_DEVICE_REGISTERED_PATH":          certPath + "/registered.json",
	"REGISTRATION_AGENT_SERVICE_KEY_PATH":                certPath + "/client.key",
	"REGISTRATION_AGENT_SERVICE_CLIENT_CERTIFICATE_PATH": certPath + "/client.pem",
	"REGISTRATION_AGENT_SERVICE_CA_CERTIFICATE_PATH":     certPath + "/ca.pem",
	"REGISTRATION_AGENT_SERVICE_NATS_URL_PATH":           certPath + "/nats-url.txt",
	"REGISTRATION_AGENT_DEVICE_TYPE":                     "laptop",
	"REGISTRATION_AGENT_NETWORK_INTERFACE":               wirelessDevice[0], //Assuming there is only one wireless device
	"REGISTRATION_AGENT_DEVICE_CONFIG_PATH":              configPath,
}

// Method to get the heading message of screen
func (m ScreensMethods) RegistrationAgentHeading() string {
	return "Registration Agent"
}

func (m ScreensMethods) RegistrationAgent() {

	if !(haveMountedSystem) {
		pterm.Error.Printfln("No system has been mounted")
		goToNextScreen()
		return
	}
	// Set environment variables
	setEnv()
	// Execute registration-agent-laptop binary
	global.ExecCommandWithLiveMessage(registrationAgentScript)
	_, err := global.ExecCommand("sudo", "chmod", "-R", "777", certPath)
	if err != 0 {
		panic(err)
	}
	// Wait for 3 seconds for user to read the finish log
	time.Sleep(3)
	goToNextScreen()

}

func setEnv() {
	// Create folder for certificates and config
	_, err := global.ExecCommand("sudo", "mkdir", "-p", certPath)
	if err != 0 {
		panic(err)
	}

	// Set the env variables
	for env, value := range registrationEnv {
		os.Setenv(env, value)
	}

	//writeEnv2File()
}

// InterfacesFromSysfs returns the wireless interfaces found in the SysFS (/sys/class/net)
func interfacesFromSysfs() []string {
	s := []string{}
	base := "/sys/class/net"
	matches, _ := filepath.Glob(path.Join(base, "*"))

	//  look for the wireless folder in each interfces directory to determine if it is a wireless device
	for _, iface := range matches {
		if stat, err := os.Stat(path.Join(iface, "wireless")); err == nil && stat.IsDir() {
			s = append(s, path.Base(iface))
		}
	}

	return s
}

func writeEnv2File() {

	f, err := os.Create(envFile)
	if err != nil {
		panic(err)

	}

	defer func() {
		f.Close()
	}()

	for env, value := range registrationEnv {
		_, err = f.WriteString(env + "=" + value + global.NEW_LINE_CHAR)
		if err != nil {
			panic(err)
		}
	}

}
