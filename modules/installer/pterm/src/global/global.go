package global

import (
	"os/exec"
	"strings"
	//"unicode/utf8"
)

type CommandOutput struct {
	Message   []string
	Errorcode int
}

var Images string
var Image2Install string

func ExecCommand(cmd string, arg ...string) CommandOutput {

	s := exec.Command(cmd, arg...)

	stdout, err := s.Output()
	errorcode := 0
	message := strings.Split(string(stdout), string(10))
	if err != nil {
		errorcode = -1
		message = strings.Split(err.Error(), string(10))
	}
	if strings.Split(strings.Split(string(stdout), string(10))[0], string(32))[0] == "Error:" {
		errorcode = -1
	}
	return CommandOutput{message, errorcode}
}
