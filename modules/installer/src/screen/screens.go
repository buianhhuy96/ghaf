package screen

import (
	"os"
	"path/filepath"
	"strconv"
	"strings"
)

type ScreensMethods struct{}

// Defines constants and variables for installation process
const nextScreenMsg = ">>--Skip to next step------->>"
const previousScreenMsg = "<<--Back to previous step---<<"

var ConnectionStatus = false
var selectedPartition string
var currentInstallationScreen = 0
var Screens = make(map[int]string)
var screenDir = "./screen"

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

func InitScreen() {
	files, err := os.ReadDir(screenDir)
	if err != nil {
		panic(err)
	}

	for _, file := range files {
		// Split file name into arrays/slices
		// "00-WelcomeScreen.go" => ["00" "WelcomeScreen"]
		fileName := strings.Split(file.Name()[:len(file.Name())-len(filepath.Ext(file.Name()))], "-")

		// Skip if file name not following above format (e.g "screen.go")
		if len(fileName) != 2 {
			continue
		}

		order, _ := strconv.Atoi(fileName[0])
		Screens[order] = fileName[1]
	}
}
