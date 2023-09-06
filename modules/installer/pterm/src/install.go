package main

import (
	"time"

	"ghaf-installer/screen"

	"github.com/pterm/pterm"
	//"unicode/utf8"
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

	for (screen.GetCurrentScreen()) < len(screen.Screens) {
		currentScreen := screen.GetCurrentScreen()
		showcase(screen.Screens[currentScreen].Heading, 2,
			screen.Screens[currentScreen].Show)

	}

}
