package screen

// "unicode/utf8"

const nextScreenMsg = ">>--Skip to next step------->>"
const previousScreenMsg = "<<--Back to previous step---<<"

var ConnectionStatus = false
var currentInstallationScreen = 0

func GetCurrentScreen() int {
	return currentInstallationScreen
}

func goToNextScreen() {
	currentInstallationScreen++
}

func backToPreviousScreen() {
	currentInstallationScreen--
}

func checkSkipScreen(input string) bool {
	if input == nextScreenMsg {
		currentInstallationScreen++
		return true
	} else if input == previousScreenMsg {
		currentInstallationScreen--
		return true
	}
	return false
}

var Screens = map[int](struct {
	Heading string
	Show    func()
}){
	0: {"Welcome", WelcomeScreen},
	1: {"Connect to network", WifiScreen},
	2: {"Select image", ImageScreen},
	3: {"Select partitions and install", PartitionScreen},
	4: {"Installation Complete", ExitScreen},
}
