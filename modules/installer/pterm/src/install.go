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

type CommandOutput struct {
    message  []string
    errorcode int
}

var second = time.Second
func clear() {
	print("\033[H\033[2J")
}

func showcase(title string, seconds int, content func()) {
	pterm.DefaultHeader.WithBackgroundStyle(pterm.NewStyle(pterm.BgLightGreen)).WithFullWidth().Println(title)
	pterm.Println()
	time.Sleep(second / 2)
	content()
	time.Sleep(second * time.Duration(seconds))
	print("\033[H\033[2J")
}

func execCommand(cmd string, arg ...string) CommandOutput {


    s := exec.Command(cmd, arg...)
	
    stdout, err := s.Output()
    if err != nil {
        return CommandOutput{strings.Split(err.Error(),string(10)),-1}
    }

    return CommandOutput{strings.Split(string(stdout),string(10)),0}
}

var ghaf = "nixos.img"
func main() {
	ghaf_image, _ := os.Stat(ghaf)
	image_size := ghaf_image.Size()
	// Print a large text with differently colored letters.
	showcase("Welcome", 2, func() {
		area, _ := pterm.DefaultArea.WithCenter().WithCenter().Start()

		for i := 0; i < 4; i++ {

			str, _ := pterm.DefaultBigText.WithLetters(
				putils.LettersFromStringWithStyle("G", pterm.FgLightGreen.ToStyle()),
				putils.LettersFromString("haf")).
				Srender()
			area.Update(str)
			time.Sleep(time.Second)
		}
	})
	showcase("Connect to network", 5, func()  {

		wifi := execCommand("nmcli", "--fields", "SSID,BARS,SECURITY", "dev", "wifi")
		if len(wifi.message) > 0 {
			wifi_list := wifi.message;
			//separator,_:=  utf8.DecodeRune([]byte{226, 150, 130})

			selected_wifi, _ := pterm.DefaultInteractiveSelect. 
								WithMaxHeight(20).
								WithOptions(wifi_list[1:]).
								Show("Wifi list \n  " + wifi_list[0])

			SSID := strings.TrimSpace(strings.Split(string(selected_wifi),string(32))[0])
			pterm.Info.Printfln("Connect to %s", SSID)
			// TO-DO: No password required
			password, _ := pterm.DefaultInteractiveTextInput.
							WithMultiLine(false).
							WithMask("*").
							Show("Password")
			
			wifiConnectingSpinner, _ := pterm.DefaultSpinner.WithShowTimer(false).WithRemoveWhenDone(true).Start("Connecting to " + SSID)
			connection := execCommand("nmcli", "dev", "wifi", "connect", SSID, "password", password)
			wifiConnectingSpinner.Stop()//pterm.Println(connection.errorcode) // Blank line
			if (connection.errorcode == 0){
				pterm.Info.Printfln("Connected")
			} else {

				pterm.Error.Printfln("Failed to connect to " + SSID)
			}

		}

	})
	showcase("Choose Partitions", 2, func()  {
		drives := execCommand("lsblk", "-d", "-e7")
		if len(drives.message) > 0 {
			drives_list := drives.message;
			selected_drive, _ := pterm.DefaultInteractiveSelect.
									WithOptions(drives_list[1:len(drives_list)-1]).
									Show("Please select device to install Ghaf \n  " + drives_list[0])
			pterm.Info.Printfln("Selected: %s", pterm.Green(strings.TrimSpace(strings.Split(string(selected_drive),string(32))[0])))
			write_image := "dd if=" + ghaf + " of=/dev/" +strings.TrimSpace(strings.Split(string(selected_drive),string(32))[0])+ " conv=sync bs=4K status=progress";
			s := exec.Command("sudo", strings.Split(write_image," ")...)
			stdout, err := s.StderrPipe()
			s.Start()
			if err != nil {
				pterm.Info.Printfln("Error during installation")
			}
			last_progessbar_value := int(0)
			p, _ := pterm.DefaultProgressbar.WithTotal(int(image_size)).WithTitle("Copied").Start()
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
					p.Add((current-last_progessbar_value))
					last_progessbar_value = current
				}

			}
			
			s.Wait()
			p.Add((int(image_size)-last_progessbar_value))
			pterm.Info.Printfln("Installation Completed")




		}
	})
}
