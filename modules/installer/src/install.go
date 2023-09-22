package main

import (
	"ghaf-installer/screen"
	"reflect"
	"time"

	"github.com/pterm/pterm"
)

func showcase(title string, seconds int, content func()) {
	pterm.DefaultHeader.WithBackgroundStyle(pterm.NewStyle(pterm.BgGreen)).
		WithFullWidth().
		Println(title)
	pterm.Println()
	time.Sleep(time.Second / 2)
	content()
	time.Sleep(time.Second * time.Duration(seconds))
	print("\033[H\033[2J")
}

func main() {
	// use for retrieving methods
	var methodlist screen.ScreensMethods

	// Look for all screens in folder ./screen
	screen.InitScreen()
	for (screen.GetCurrentScreen()) < len(screen.Screens) {
		currentScreen := screen.GetCurrentScreen()

		screenHeading := reflect.ValueOf(methodlist).
			MethodByName(screen.Screens[currentScreen] + "Heading").
			Call(nil)[0].
			Interface().(string)

		screenFunc := reflect.ValueOf(methodlist).
			MethodByName(screen.Screens[currentScreen]).
			Interface().(func())

		showcase(screenHeading, 2, screenFunc)
	}

}
