package tutorials

import (
	"net/url"
	"ghaf-fyne/pic"
	"fyne.io/fyne/v2"
	"fyne.io/fyne/v2/canvas"
	//"fyne.io/fyne/v2/cmd/fyne_demo/data"
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/widget"
)
 
func parseURL(urlStr string) *url.URL {
	link, err := url.Parse(urlStr)
	if err != nil {
		fyne.LogError("Could not parse URL", err)
	}

	return link
}

func welcomeScreen(_ fyne.Window) fyne.CanvasObject {
	logo := canvas.NewImageFromResource(pic.GetLogo())
	logo.FillMode = canvas.ImageFillContain
	if fyne.CurrentDevice().IsMobile() {
		logo.SetMinSize(fyne.NewSize(192, 192))
	} else {
		logo.SetMinSize(fyne.NewSize(256, 256))
	}

	return container.NewCenter(container.NewVBox(
		widget.NewLabelWithStyle("Welcome to the Ghaf installer", fyne.TextAlignCenter, fyne.TextStyle{Bold: true}),
		logo,
		container.NewHBox(
			widget.NewLabel(""),
			widget.NewHyperlink("github", parseURL("https://github.com/tiiuae/ghaf")),
			widget.NewLabel(""),
			widget.NewLabel("-"),
			widget.NewLabel(""),
			widget.NewHyperlink("documentation", parseURL("https://tiiuae.github.io/ghaf/")),
		),
		widget.NewLabel(""), // balance the header on the tutorial screen we leave blank on this content
	))
}
