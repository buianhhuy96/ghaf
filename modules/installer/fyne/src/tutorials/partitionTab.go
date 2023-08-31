package tutorials

import (
	"fmt"
    "strings"

	"fyne.io/fyne/v2"
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/widget"
)

func partitionTab(_ fyne.Window) fyne.CanvasObject {
	drives := execCommand([]string{"lsblk", "-d", "-e7"})
	drivesList := drives.message;
	radioAlign := widget.NewRadioGroup(drivesList[1:len(drivesList)-1], func(s string) {
		selectPartition(strings.TrimSpace(strings.Split(string(s),string(32))[0]))
		fmt.Println(selectedPartition)
	})
	//radioAlign.SetSelected(drivesList[0])
	fixed := container.NewVBox(radioAlign)

	//grid := makeTextGrid()
	return container.NewBorder(fixed, nil, nil, nil, nil)
		//container.NewGridWithRows(2, rich, entryLoremIpsum))
	//return nil;
}