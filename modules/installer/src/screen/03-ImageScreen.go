package screen

import (
	"ghaf-installer/global"
	"strings"

	"github.com/pterm/pterm"
)

// Method to get the heading message of screen
func (m ScreensMethods) ImageScreenHeading() string {
	return "Select image"
}

func (m ScreensMethods) ImageScreen() {
	// Image list is a string with format:
	// <Image 1>||<Path to image 1>||<Image 2>||<Path to image 2>||....
	imageSeparated := strings.Split(string(global.Images), string("||"))
	var imageList []string

	// Loop to retrieve names of all images
	for i, imageAndLocation := range imageSeparated {
		if i%2 == 0 {
			imageList = append(imageList, imageAndLocation)
		}
	}

	// Add skip options and print option list to select which image to install
	imageList = appendScreenControl(imageList)
	selectedImage, _ := pterm.DefaultInteractiveSelect.
		WithOptions(imageList).
		Show("Please select image to install")

	// If skip option is selected
	if checkSkipScreen(selectedImage) {
		return
	}

	// Get image path based on name
	for i, imageAndLocation := range imageSeparated {
		if selectedImage == imageAndLocation {
			global.Image2Install = imageSeparated[i+1]
			break
		}
	}

	goToScreen(GetCurrentScreen() + 1)

}
