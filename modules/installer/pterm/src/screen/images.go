package screen

import (
	"ghaf-installer/global"
	"strings"

	"github.com/pterm/pterm"
	//"unicode/utf8"
)

func ImageScreen() {
	imageSeparated := strings.Split(string(global.Images), string("||"))
	var imageList []string
	for i, imageAndLocation := range imageSeparated {
		if i%2 == 0 {
			imageList = append(imageList, imageAndLocation)
		}
	}

	imageList = append([]string{nextScreenMsg}, imageList...)
	imageList = append([]string{previousScreenMsg}, imageList...)
	selectedImage, _ := pterm.DefaultInteractiveSelect.
		WithOptions(imageList).
		Show("Please select image to install")

	if checkSkipScreen(selectedImage) {
		return
	}

	for i, imageAndLocation := range imageSeparated {
		if selectedImage == imageAndLocation {
			global.Image2Install = imageSeparated[i+1]
			break
		}
	}

	goToNextScreen()

}
