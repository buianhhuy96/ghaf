package screen

import (
	"bufio"
	"ghaf-installer/global"
	"math"
	"os"
	"os/exec"
	"strconv"
	"strings"

	"github.com/pterm/pterm"
)

func PartitionScreen() {
	var drivesList []string
	var drivesListHeading, selectedDrive string

	drivesList = append([]string{nextScreenMsg}, drivesList...)
	drivesList = append([]string{previousScreenMsg}, drivesList...)

	// If no images are selected to install
	if len(global.Image2Install) == 0 {
		pterm.Error.Printfln("No image is selected for the installation")
	} else {
		// Get all block devices
		drives := global.ExecCommand("lsblk", "-d", "-e7")
		if len(drives.Message) > 0 {
			drivesListHeading = "  " + drives.Message[0]
			drivesList = append(drivesList, drives.Message[1:len(drives.Message)-1]...)

		}
	}

	// Print options to select device to install image
	selectedDrive, _ = pterm.DefaultInteractiveSelect.
		WithOptions(drivesList).
		Show("Please select device to install Ghaf \n  " + drivesListHeading)

	// If a skip option selected
	if checkSkipScreen(selectedDrive) {
		return
	}

	/***************** Start Installing *******************/
	image, _ := os.Stat(global.Image2Install)
	imageSize := image.Size()
	pterm.Info.Printfln("Selected: %s", pterm.Green(strings.TrimSpace(strings.Split(string(selectedDrive), string(32))[0])))
	writeImage := "dd if=" + global.Image2Install + " of=/dev/" + strings.TrimSpace(strings.Split(string(selectedDrive), string(32))[0]) + " conv=sync bs=4K status=progress"
	s := exec.Command("sudo", strings.Split(writeImage, " ")...)
	stdout, err := s.StderrPipe()
	s.Start()
	if err != nil {
		pterm.Info.Printfln("Error during installation")
	}

	// No error occur, collect progress to print as percentage
	lastProgessbarValue := int(0)
	p, _ := pterm.DefaultProgressbar.WithTotal(int(imageSize)).WithTitle("Copied").Start()
	counter := -1
	scanner := bufio.NewScanner(stdout)
	scanner.Split(bufio.ScanWords)
	for scanner.Scan() {

		counter = int(math.Mod(float64(counter+1), 11))
		if counter == 0 {
			current, err := strconv.Atoi(scanner.Text())
			if err != nil {
				continue
			}
			p.Add((current - lastProgessbarValue))
			lastProgessbarValue = current
		}
	}

	s.Wait()
	p.Add((int(imageSize) - lastProgessbarValue))

	// dd command finished
	pterm.Info.Printfln("Installation Completed")

	goToNextScreen()
	return

}
