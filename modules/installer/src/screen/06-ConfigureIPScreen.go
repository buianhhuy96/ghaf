package screen

import (
	"ghaf-installer/global"
	"net"
	"os"
	"strings"
	"time"
	"bytes"
	"text/template"

	"github.com/pterm/pterm"
)

var UidEth = "d3ba46d5-6065-37c7-94a7-0df969aca945"
var UidMesh = "4f3b719f-6a2a-4c7b-95be-afc4c912ca95"
var DeviceEth = "eth0"
var DeviceMesh = "mesh0"
var IPConfigFilePathNetVM = "/var/netvm/netconf/"
var IPConfigFilePathDockerVM = "/var/fogdata/"
var HostnameConfigFile = "hostname"
var IPConfigFile = "ip-address"
var NMConfigFileEth = "WiredEth.nmconnection"
var NMConfigFileMesh = "WiredMesh.nmconnection"
var NMTemplate = `[connection]
id={{.Id}}
uuid={{.Uid}}
type=ethernet
autoconnect-priority=-999
interface-name={{.Device}}
timestamp=1695890834

[ethernet]
mtu=1460

[ipv4]
address1={{.Ip}}
method=auto

[ipv6]
addr-gen-mode=default
method=auto

[proxy]`

var IPAddrTemplate   = "{{.Ip}}"
var HostnameTemplate = "{{.Hostname}}"

type NMConnection struct {
	Id       string
	Uid      string
	Ip       string
	Device   string
	Hostname string
}

// Method to get the heading message of screen
func (m ScreensMethods) ConfigureIPScreenHeading() string {
	return "Configure IP for destination system"
}

func (m ScreensMethods) ConfigureIPScreen() {

	if !(haveMountedSystem) {
		pterm.Error.Printfln("No system has been mounted")
		goToNextScreen()
		return
	}

	var sysIP string
	setupIP := false
	// Ask user for input IP address
	for !setupIP {
		userIP, _ := pterm.DefaultInteractiveTextInput.
			WithMultiLine(false).
			Show("IP address for destination system (default: 192.168.248.1/24)")
		// If leave empty, use default IP
		if strings.TrimSpace(userIP) == "" {
			sysIP = "192.168.248.1/24"
			setupIP = true
			// If not empty, validate if IP is valid
		} else if validateIP(strings.TrimSpace(userIP)) {
			sysIP = strings.TrimSpace(userIP)
			setupIP = true
		} else {
			pterm.Error.Printfln("Input IP address is not valid IPv4 format (x.x.x.x/port)")
		}
	}

	pterm.Info.Printfln("System IP address is: " + sysIP)

	// Write to IP config files
	writeConnectionFile(NMConnection{"WireEth0", UidEth,  sysIP, DeviceEth, ""}, NMTemplate, NMConfigFileEth, IPConfigFilePathNetVM, "600")
	writeConnectionFile(NMConnection{"WireMesh0", UidMesh, sysIP, DeviceMesh, ""}, NMTemplate, NMConfigFileMesh, IPConfigFilePathNetVM, "600")
	writeConnectionFile(NMConnection{"", "", strings.Split(sysIP, "/")[0], "", ""}, IPAddrTemplate, IPConfigFile, IPConfigFilePathNetVM, "644")
	writeConnectionFile(NMConnection{"", "", strings.Split(sysIP, "/")[0], "", ""}, IPAddrTemplate, IPConfigFile, IPConfigFilePathDockerVM, "644")
	writeConnectionFile(NMConnection{"", "", strings.Split(sysIP, "/")[0], "", "dockervm"}, HostnameTemplate, HostnameConfigFile, IPConfigFilePathDockerVM, "644")

	time.Sleep(1)

	pterm.Info.Printfln("Config for IP address has been copied to destination system")
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

func writeConnectionFile(con NMConnection, tmplt string, fname string, path string, permissions string) {
	var buffer bytes.Buffer

	tmpl, err := template.New("template").Parse(tmplt)
	if err != nil {
		panic(err)
	}

	err = tmpl.Execute(&buffer, con)
	if err != nil {
		panic(err)
	}
	_, err_int := global.ExecCommand("mkdir", "-p", mountPoint + path)
	if err_int != 0 {
		panic(err_int)
	}

	f, err := os.Create(mountPoint + path + fname)
	if err != nil {
		panic(err)

	}

	defer func() {
		f.Close()
	}()

	_, err = f.WriteString(buffer.String())
	if err != nil {
		panic(err)
	}
	err = f.Close()
	if err != nil {
		panic(err)
	}

	_, err_int = global.ExecCommand("sudo", "chmod", permissions, mountPoint + path + fname)
	if err_int != 0 {
		panic(err)
	}
}
