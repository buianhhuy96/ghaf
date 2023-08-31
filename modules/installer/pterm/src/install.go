package main

import (
	"time"
	"bufio"
	"strconv"
	"github.com/pterm/pterm"
	"github.com/pterm/pterm/putils"
    "os/exec"
    "os"
    "strings"
    //"unicode/utf8"
	"math"


)
type installationStep int64
const (
	Welcome installationStep = iota
	Wifi  
	Image
	Partitions  
	Exit
)
const nextStep 	   =  ">>--Skip to next step------->>"
const previousStep =  "<<--Back to previous step---<<"

type CommandOutput struct {
    message  []string
    errorcode int
}
type imageInfo struct {
    name  string
    location string
}

var second = time.Second
var connectionStatus = false
var currentInstallationStep = Welcome
var images string
var image2Install string



func showcase(title string, seconds int, content func()) {
	pterm.DefaultHeader.WithBackgroundStyle(pterm.NewStyle(pterm.BgGreen)).WithFullWidth().Println(title)
	pterm.Println()
	time.Sleep(second / 2)
	content()
	time.Sleep(second * time.Duration(seconds))
	print("\033[H\033[2J")
}

func execCommand(cmd string, arg ...string) CommandOutput {


    s := exec.Command(cmd, arg...)
	
    stdout, err := s.Output()
	errorcode := 0
	message := strings.Split(string(stdout),string(10))
    if (err != nil) {
		errorcode = -1
		message = strings.Split(err.Error(),string(10))
    }
	if (strings.Split(strings.Split(string(stdout),string(10))[0],string(32))[0] == "Error:") {
		errorcode = -1
	}
    return CommandOutput{message,errorcode}
}

func checkSkipStep (input string) bool {
	if (input == nextStep) {
		currentInstallationStep++
		return true
	} else if input == previousStep {
		currentInstallationStep--
		return true
	}
	return false
}

func welcomeScreen () {
	area, _ := pterm.DefaultArea.WithCenter().WithCenter().Start()
	for i := 0; i < 4; i++ {
		str, _ := pterm.DefaultBigText.WithLetters(
			putils.LettersFromStringWithStyle("G", pterm.FgLightGreen.ToStyle()),
			putils.LettersFromString("haf")).
			Srender()
		area.Update(str)
		time.Sleep(time.Second)
	}
	currentInstallationStep++
	return
}

func wifiScreen () {
	wifiConnect := execCommand("nmcli", "-t", "--fields", "SSID,SIGNAL,SECURITY", "dev", "wifi")
		skipWifi := false
		if len(wifiConnect.message) == 0 {
			skipWifi = true
			currentInstallationStep = Partitions
			return
		}
		for (!connectionStatus && !skipWifi) { 
			wifiList := wifiConnect.message[0:len(wifiConnect.message)-1]
			longestWifiSSID := 0
			for _,wifi := range wifiList {
				wSSID := strings.Split(string(wifi),":")[0]
				if len(wSSID) > longestWifiSSID {
					longestWifiSSID = len(wSSID)
				}
			}
			var wifiListBeautified []string

			for _,wifi := range wifiList {
				wSSID := strings.Split(string(wifi),":")[0]
				wSignal := strings.Split(string(wifi),":")[1]
				wSSIDBeautified := wSSID + strings.Repeat(" ", longestWifiSSID + 2 -len(wSSID))
				wSignalBeautified := wSignal + strings.Repeat(" ", 8 -len(wSignal))
				wSecurity := strings.Split(string(wifi),":")[2]
				wifiListBeautified = append(wifiListBeautified, wSSIDBeautified + "||" + wSignalBeautified + "||" + wSecurity)
			}



			wifiListBeautified = append([]string{ nextStep }, wifiListBeautified...)
			wifiListBeautified = append([]string{ previousStep }, wifiListBeautified...)
			wifiListHeading := "SSID" + strings.Repeat(" ", longestWifiSSID + 2 -len("SSID")) + "||SIGNAL  ||SECURITY" 
			selectedWifi, _ := pterm.DefaultInteractiveSelect. 
								WithMaxHeight(20).
								WithOptions(wifiListBeautified).
								Show("Wifi list \n  " + wifiListHeading)

			if checkSkipStep(selectedWifi) {
				skipWifi = true
				return
			}

			SSID := strings.TrimSpace(strings.Split(string(selectedWifi),string("||"))[0])
			pterm.Info.Printfln("Connect to %s", SSID)

			password, _ := pterm.DefaultInteractiveTextInput.
							WithMultiLine(false).
							WithMask("*").
							Show("Password (If no password, leave empty)")
			
			wifiConnectingSpinner, _ := pterm.DefaultSpinner.WithShowTimer(false).WithRemoveWhenDone(true).Start("Connecting to " + SSID)
			connection := execCommand("nmcli", "dev", "wifi", "connect", SSID, "password", password)
			wifiConnectingSpinner.Stop()//pterm.Println(connection.errorcode) // Blank line
			if (connection.errorcode == 0){
				connectionStatus = true
				pterm.Info.Printfln("Connected")
			} else {
				connectionStatus = false
				pterm.Error.Printfln("Failed to connect to " + SSID)
			}
		}
	
		currentInstallationStep++
		
}

func imageScreen () {
	imageSeparated := strings.Split(string(images),string("||"))
	var imageList []string
	for i,imageAndLocation := range imageSeparated {
		if(i % 2 == 0){
			imageList = append(imageList, imageAndLocation)
		}		
	}

	imageList = append([]string{ nextStep }, imageList...)
	imageList = append([]string{ previousStep }, imageList...)
	selectedImage, _ := pterm.DefaultInteractiveSelect.
							WithOptions(imageList).
							Show("Please select image to install")
	
	if checkSkipStep(selectedImage) {
		return
	}

	for i,imageAndLocation := range imageSeparated {
		if selectedImage == imageAndLocation {
			image2Install = imageSeparated[i+1]
			break;
		}	
	}
	
	currentInstallationStep++

}

func partitionScreen () {

	if len(image2Install) == 0 {
		pterm.Error.Printfln("No image is selected for the installation")
		currentInstallationStep--
		return
	}
	image, _ := os.Stat(image2Install)
	imageSize := image.Size()
	drives := execCommand("lsblk", "-d", "-e7")
	var drivesListHeading, selectedDrive string

	if len(drives.message) > 0 {
		drivesListHeading = "  " + drives.message[0];
		drivesList := drives.message[1:len(drives.message)-1];
		drivesList = append([]string{ nextStep }, drivesList...)
		drivesList = append([]string{ previousStep }, drivesList...)
		selectedDrive, _ = pterm.DefaultInteractiveSelect.
								WithOptions(drivesList).
								Show("Please select device to install Ghaf \n  " + drivesListHeading)
		if checkSkipStep(selectedDrive) {
			return
		}
	} 

	pterm.Info.Printfln("Selected: %s", pterm.Green(strings.TrimSpace(strings.Split(string(selectedDrive),string(32))[0])))
	writeImage := "dd if=" + image2Install + " of=/dev/" +strings.TrimSpace(strings.Split(string(selectedDrive),string(32))[0])+ " conv=sync bs=4K status=progress";
	s := exec.Command("sudo", strings.Split(writeImage," ")...)
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
		
		counter = int(math.Mod(float64(counter+1),11))
		if counter == 0 {
			current, err := strconv.Atoi(scanner.Text())
			if err != nil {
				continue
			}
			p.Add((current-lastProgessbarValue))
			lastProgessbarValue = current
		}
	}
	
	s.Wait()
	p.Add((int(imageSize)-lastProgessbarValue))
	pterm.Info.Printfln("Installation Completed")

	currentInstallationStep++
	return
		
}


func main() {
	for currentInstallationStep != Exit{
		switch currentInstallationStep{
		case Welcome:
			showcase("Welcome", 2, welcomeScreen)
		case Wifi:
			showcase("Connect to network", 1, wifiScreen)
		case Image:
			showcase("Select image", 1, imageScreen)
		case Partitions:
			showcase("Select partitions", 1, partitionScreen)
		}
	}

}
