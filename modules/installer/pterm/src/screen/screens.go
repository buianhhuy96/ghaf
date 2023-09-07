package screen

// Defines constants and variables for installation process
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
		goToNextScreen()
		return true
	} else if input == previousScreenMsg {
		backToPreviousScreen()
		return true
	}
	return false
}

/*********** Storage for all screens of installation process *********/
/**** To insert new screen, the format should be:

	<Screen order>, {<Screen Heading>,<Display function>}

	* Screen order: type integer, must start from 0 and be adjacent
	* Screen Heading: type string, message to display on the heading
	* Display function: type func(), function to perform actions and display as screen

*****/
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
