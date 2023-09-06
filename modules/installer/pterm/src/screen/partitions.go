package screen

import (
	"bufio"
	"ghaf-installer/global"
	"os"
	"os/exec"
	"strconv"
	"strings"

	"github.com/pterm/pterm"

	//"unicode/utf8"
	"math"
)

func PartitionScreen() {
	var drivesList []string
	var drivesListHeading, selectedDrive string

	drivesList = append([]string{nextScreenMsg}, drivesList...)
	drivesList = append([]string{previousScreenMsg}, drivesList...)
	if len(global.Image2Install) == 0 {
		pterm.Error.Printfln("No image is selected for the installation")
	} else {
		drives := global.ExecCommand("lsblk", "-d", "-e7")
		if len(drives.Message) > 0 {
			drivesListHeading = "  " + drives.Message[0]
			drivesList = append(drivesList, drives.Message[1:len(drives.Message)-1]...)

		}
	}

	selectedDrive, _ = pterm.DefaultInteractiveSelect.
		WithOptions(drivesList).
		Show("Please select device to install Ghaf \n  " + drivesListHeading)

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
	pterm.Info.Printfln("Installation Completed")

	goToNextScreen()
	return

}
