package screen

// Method to get the heading message of screen
func (m ScreensMethods) CheckHardwareHeading() string {
	return "Check Hardware Compatibility"
}

func (m ScreensMethods) CheckHardware() {
	goToScreen(GetCurrentScreen() + 1)

}
