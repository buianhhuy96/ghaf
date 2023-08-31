package tutorials

import (
	"fmt"
    "strings"
    "os"
    "os/exec"
	"bufio"
	"strconv"
	"math"

	"fyne.io/fyne/v2"
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/widget"
)

var ch = make(chan int)
func startInstalling() {


	ghafImage, _ := os.Stat(ghaf)
	fmt.Println(ghaf)
	imageSize := ghafImage.Size()
	
	writeImage := "dd if=" + ghaf + " of=/dev/" + selectedPartition + " conv=sync bs=4K status=progress";
	cmd := exec.Command("sudo", strings.Split(writeImage," ")...)
	stdout, err := cmd.StderrPipe()
	cmd.Start()
	if err != nil {
		return 
	}

	counter := -1
	scanner := bufio.NewScanner(stdout)
	scanner.Split(bufio.ScanWords)
	for scanner.Scan() {		
		counter = int(math.Mod(float64(counter+1),11))
		if counter == 0 {
			current, err := strconv.Atoi(scanner.Text())
			
			progress.SetValue(float64(current)/float64(imageSize))
			if err != nil {
				continue
			}
		}

	}
	setGhafInstalled(true)
	progress.SetValue(1)
	
}

func installTab(_ fyne.Window) fyne.CanvasObject {

	
//	stopProgress()

	progress = widget.NewProgressBar()
	if (checkGhafInstalled()){
		progress.SetValue(1)
	}


  
//	endProgress = make(chan interface{}, 1)
	installButton := widget.NewButton("Install Ghaf",  func() {
		if selectedPartition != "" {
			go startInstalling()
		}
	})

	select{
	case <- ch:

	  // done! check error
	default: //timeouts, ticks or anything else
  }
	return container.NewVBox(
		widget.NewLabel("Installing..."), progress,
		//widget.NewLabel("Formatted"), fprogress,
		installButton)
}
