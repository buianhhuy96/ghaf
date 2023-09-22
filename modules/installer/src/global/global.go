package global

import (
	"io"
	"log"
	"os"
	"os/exec"
	"os/signal"
	"strings"
	"syscall"

	"github.com/creack/pty"
	"golang.org/x/term"
)

const SPACE_CHAR = string(' ')
const NEW_LINE_CHAR = string('\n')

var Images string
var Image2Install string

func ExecCommand(cmd string, arg ...string) ([]string, int) {

	s := exec.Command(cmd, arg...)

	stdout, err := s.Output()
	errorcode := 0
	message := strings.Split(string(stdout), NEW_LINE_CHAR)
	if err != nil {
		errorcode = -1
		message = strings.Split(err.Error(), NEW_LINE_CHAR)
	}
	if strings.Split(strings.Split(string(stdout), NEW_LINE_CHAR)[0], SPACE_CHAR)[0] == "Error:" {
		errorcode = -1
	}
	return message, errorcode
}

func ExecCommandWithLiveMessage(cmd string, arg ...string) {

	s := exec.Command(cmd, arg...)

	out, _ := pty.Start(s)

	// Make sure to close the pty at the end.
	defer func() { _ = out.Close() }()

	// Handle pty size.
	ch := make(chan os.Signal, 1)
	signal.Notify(ch, syscall.SIGWINCH)
	go func() {
		for range ch {
			if err := pty.InheritSize(os.Stdin, out); err != nil {
				log.Printf("error resizing pty: %s", err)
			}
		}
	}()
	ch <- syscall.SIGWINCH                        // Initial resize.
	defer func() { signal.Stop(ch); close(ch) }() // Cleanup signals when done.

	// Set stdin in raw mode.
	oldState, err := term.MakeRaw(int(os.Stdin.Fd()))
	if err != nil {
		panic(err)
	}
	defer func() { _ = term.Restore(int(os.Stdin.Fd()), oldState) }() // Best effort.

	go func() {

		io.Copy(out, os.Stdin)
	}()
	_, _ = io.Copy(os.Stdout, out)
	return
}
