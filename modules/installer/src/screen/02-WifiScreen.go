package screen

import (
	"ghaf-installer/global"
	"strings"

	"github.com/pterm/pterm"
)

// Method to get the heading message of screen
func (m ScreensMethods) WifiScreenHeading() string {
	return "Connect to network"
}

func (m ScreensMethods) WifiScreen() {
	wifiConnect, _ := global.ExecCommand("nmcli", "-t", "--fields", "SSID,SIGNAL,SECURITY", "dev", "wifi")
	skipWifi := false
	if len(wifiConnect) == 0 {
		skipWifi = true
		goToNextScreen()
		return
	}
	for !ConnectionStatus && !skipWifi {
		wifiList := wifiConnect[0 : len(wifiConnect)-1]
		longestWifiSSID := 0
		for _, wifi := range wifiList {
			wSSID := strings.Split(string(wifi), ":")[0]
			if len(wSSID) > longestWifiSSID {
				longestWifiSSID = len(wSSID)
			}
		}
		var wifiListBeautified []string

		for _, wifi := range wifiList {
			wSSID := strings.Split(string(wifi), ":")[0]
			wSignal := strings.Split(string(wifi), ":")[1]
			wSSIDBeautified := wSSID + strings.Repeat(" ", longestWifiSSID+2-len(wSSID))
			wSignalBeautified := wSignal + strings.Repeat(" ", 8-len(wSignal))
			wSecurity := strings.Split(string(wifi), ":")[2]
			wifiListBeautified = append(wifiListBeautified, wSSIDBeautified+"||"+wSignalBeautified+"||"+wSecurity)
		}

		wifiListBeautified = append([]string{nextScreenMsg}, wifiListBeautified...)
		wifiListBeautified = append([]string{previousScreenMsg}, wifiListBeautified...)
		wifiListHeading := "SSID" + strings.Repeat(" ", longestWifiSSID+2-len("SSID")) + "||SIGNAL  ||SECURITY"
		selectedWifi, _ := pterm.DefaultInteractiveSelect.
			WithMaxHeight(20).
			WithOptions(wifiListBeautified).
			Show("Wifi list \n  " + wifiListHeading)

		if checkSkipScreen(selectedWifi) {
			skipWifi = true
			return
		}

		SSID := strings.TrimSpace(strings.Split(string(selectedWifi), string("||"))[0])
		pterm.Info.Printfln("Connect to %s", SSID)

		password, _ := pterm.DefaultInteractiveTextInput.
			WithMultiLine(false).
			WithMask("*").
			Show("Password (If no password, leave empty)")

		wifiConnectingSpinner, _ := pterm.DefaultSpinner.
			WithShowTimer(false).
			WithRemoveWhenDone(true).
			Start("Connecting to " + SSID)
		_, err := global.ExecCommand("nmcli", "dev", "wifi", "connect", SSID, "password", password)
		wifiConnectingSpinner.Stop()
		if err == 0 {
			ConnectionStatus = true
			pterm.Info.Printfln("Connected")
		} else {
			ConnectionStatus = false
			pterm.Error.Printfln("Failed to connect to " + SSID)
		}
	}

	goToNextScreen()

}
