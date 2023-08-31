package tutorials

import (
	"fmt"
    "strings"

	"fyne.io/fyne/v2"
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/widget"
	"fyne.io/fyne/v2/dialog"
)

var wifiList [][]string
func listAvailableWifi() {
	cmd := execCommand([]string {"nmcli", "-t", "--fields", "SSID,SIGNAL,SECURITY", "dev", "wifi"})
	for i:=0; i < len(cmd.message)-1; i++ {
		wifiList = append(wifiList,strings.Split(cmd.message[i],":"))
	}

}

func connectWifi(SSID, password string) {
	connection := []string {"nmcli", "dev", "wifi", "connect", SSID,  "password",password} ;
	cmd := execCommand(connection)
	if (cmd.errorcode == 0){
		fmt.Println("Connected")
	}
	fmt.Println(cmd.message)
}

func loginWifi(win fyne.Window) {
	username := widget.NewEntry()
	username.Text = selectedWifi
	username.Disable()
	password := widget.NewPasswordEntry()
	//password.Validator = validation.NewRegexp(`^[A-Za-z0-9_-]+$`, "password can only contain letters, numbers, '_', and '-'")
	items := []*widget.FormItem{
		widget.NewFormItem("Username", username),
		widget.NewFormItem("Password", password),
	}
	
	wifiForm := dialog.NewForm("Login...", "Log In", "Cancel", items, func(b bool) {
		if !b {
			return
		}
		go connectWifi(selectedWifi,password.Text)
	}, win)
	wifiForm.Resize(fyne.MeasureText(username.Text, 40, username.TextStyle))
	wifiForm.Show()
}

func makeWifiList(win fyne.Window) []fyne.CanvasObject {
	var items []fyne.CanvasObject
	listAvailableWifi()
	for i := 0; i < len(wifiList); i++ {
		//index := i // capture
		// TO-DO call for password
		wifiSSID := wifiList[i][0]
		wifiButton := widget.NewButton(wifiSSID + "", func() {
			selectedWifi = wifiSSID
			loginWifi(win)
		})
		wifiButton.Alignment = widget.ButtonAlignLeading
		items = append(items, wifiButton )
	}

	return items
}

func wifiTab(win fyne.Window) fyne.CanvasObject {
	//hlist := makeButtonList(20)
	vlist := makeWifiList(win)

	//horiz := container.NewHScroll(container.NewHBox(hlist...))
	vert := container.NewVScroll(container.NewVBox(vlist...))
	//}
	return container.NewAdaptiveGrid(1,vert)
		//container.NewBorder(nil, nil, nil, nil, vert),
		//makeScrollBothTab())
}