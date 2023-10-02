package screen

import (
	"ghaf-installer/global"
	"net"
	"os"
	"strings"

	"github.com/pterm/pterm"
)

// Method to get the heading message of screen
func (m ScreensMethods) ConfigureIPScreenHeading() string {
	return "Select partitions and install"
}

func (m ScreensMethods) ConfigureIPScreen() {

	var sysIP string
	setupIP := false
	for !setupIP {
		userIP, _ := pterm.DefaultInteractiveTextInput.
			WithMultiLine(false).
			Show("IP address for destination system (default: 192.168.248.1/24)")
		if strings.TrimSpace(userIP) == "" {
			sysIP = "192.168.248.1/24"
			setupIP = true
		} else if validateIP(strings.TrimSpace(userIP)) {
			sysIP = strings.TrimSpace(userIP)
			setupIP = true
		} else {
			pterm.Error.Printfln("Input IP address is not valid IPv4 format (x.x.x.x/port)")
		}
	}

	pterm.Info.Printfln("System IP address is: " + sysIP)
	writeConnectionFile(sysIP)
	goToNextScreen()
	return
}

func validateIP(ip string) bool {
	ipArr := strings.Split(string(ip), "/")
	if len(ipArr) != 2 && len(ipArr) != 0 {
		return false
	}

	if net.ParseIP(ipArr[0]) == nil {
		return false
	}
	return true
}

func writeConnectionFile(ip string) {
	content := `[connection]
id=Wired1 
uuid=d3ba46d5-6065-37c7-94a7-0df969aca945   
type=ethernet
autoconnect-priority=-999
interface-name=enp0s9f0
timestamp=1695890834

[ethernet]

[ipv4]
address1=` + ip + ` 
method=auto

[ipv6]
addr-gen-mode=default
method=auto

[proxy]`

	_, err_int := global.ExecCommand("mkdir", "-p", "/home/ghaf/root/var/netvm/netconf/")
	if err_int != 0 {
		panic(err_int)
	}
	f, err := os.Create("/home/ghaf/root/var/netvm/netconf/Wired1.nmconnection")
	defer func() {
		f.Close()
	}()

	if err != nil {
		panic(err)

	}

	_, err = f.WriteString(content)
	if err != nil {
		panic(err)
	}
	err = f.Close()
	if err != nil {
		panic(err)
	}
}
