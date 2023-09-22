package screen

import (
	"bufio"
	"bytes"
	"ghaf-installer/global"
	"io"
	"os"
	"os/exec"
	"strconv"
	"strings"

	"github.com/pterm/pterm"
)

// Method to get the heading message of screen
func (m ScreensMethods) PartitionScreenHeading() string {
	return "Select partitions and install"
}

func (m ScreensMethods) PartitionScreen() {
	var drivesList []string
	var drivesListHeading string

	drivesList = append([]string{nextScreenMsg}, drivesList...)
	drivesList = append([]string{previousScreenMsg}, drivesList...)

	// If no images are selected to install
	if len(global.Image2Install) == 0 {
		pterm.Error.Printfln("No image is selected for the installation")
	} else {
		// Get all block devices
		drives, _ := global.ExecCommand("lsblk", "-d", "-e7")
		if len(drives) > 0 {
			drivesListHeading = "  " + drives[0]
			drivesList = append(drivesList, drives[1:len(drives)-1]...)

		}
	}

	// Print options to select device to install image
	selectedOption, _ := pterm.DefaultInteractiveSelect.
		WithOptions(drivesList).
		Show("Please select device to install Ghaf \n  " + drivesListHeading)

	// If a skip option selected
	if checkSkipScreen(selectedOption) {
		return
	}

	/***************** Start Installing *******************/

	selectedPartition := strings.TrimSpace(strings.Split(string(selectedOption), global.SPACE_CHAR)[0])
	pterm.Info.Printfln("Selected: %s", pterm.Green(selectedPartition))
	writeImage := "dd if=" + global.Image2Install +
		" of=/dev/" + selectedPartition +
		" conv=sync bs=4K status=progress"

	cmd := exec.Command("sudo", strings.Split(writeImage, " ")...)
	progress, _ := cmd.StderrPipe()

	cmd.Start()

	drawInstallingProgress(progress)
	cmd.Wait()

	// dd command finished
	progress.Close()
	pterm.Info.Printfln("Installation Completed")

	ghafMountingSpinner, _ := pterm.DefaultSpinner.
		WithShowTimer(false).
		WithRemoveWhenDone(true).
		Start("Mounting Partition")

	mountGhaf("/dev/" + selectedPartition)

	ghafMountingSpinner.Stop()

	pterm.Info.Printfln("Ghaf has been mounted to /boot and /root")
	goToNextScreen()
	return
}

func mountGhaf(disk string) {
	_, err := global.ExecCommand("mkdir", "-p", "/home/ghaf/boot")
	if err != 0 {
		panic(err)
	}
	_, err = global.ExecCommand("mkdir", "-p", "/home/ghaf/root")
	if err != 0 {
		panic(err)
	}
	_, err = global.ExecCommand("sudo", "mount", disk+"p1", "/home/ghaf/boot")
	if err != 0 {
		panic(err)
	}
	_, err = global.ExecCommand("sudo", "mount", disk+"p2", "/home/ghaf/root")
	if err != 0 {
		panic(err)
	}
}

func drawInstallingProgress(progress io.ReadCloser) {
	image, _ := os.Stat(global.Image2Install)
	imageSize := image.Size()
	p, _ := pterm.DefaultProgressbar.
		WithTotal(int(imageSize)).
		WithTitle("Copied").
		Start()
	lastProgessbarValue := int(0)

	scanner := bufio.NewScanner(progress)
	scanner.Split(customLineSplit)

	for scanner.Scan() {
		progress := (strings.Split(scanner.Text(), global.SPACE_CHAR))
		if len(progress) == 11 {
			current, err := strconv.Atoi(progress[0])
			if err != nil {
				continue
			}
			p.Add((current - lastProgessbarValue))
			lastProgessbarValue = current
		}
	}
}

// dropCR drops a terminal \r from the data.
func dropCR(data []byte) []byte {
	if len(data) > 0 && data[len(data)-1] == '\r' {
		return data[0 : len(data)-1]
	}
	return data
}

func customLineSplit(data []byte, atEOF bool) (advance int, token []byte, err error) {
	if atEOF && len(data) == 0 {
		return 0, nil, nil
	}

	if i := bytes.IndexByte(data, '\n'); i >= 0 {
		// We have a full newline-terminated line.
		return i + 1, dropCR(data[0:i]), nil
	}

	if i := bytes.IndexByte(data, '\r'); i >= 0 {
		// We have a full newline-terminated line.
		return i + 1, dropCR(data[0:i]), nil
	}

	// If we're at EOF, we have a final, non-terminated line. Return it.
	if atEOF {
		return len(data), dropCR(data), nil
	}
	// Request more data.
	return 0, nil, nil
}
