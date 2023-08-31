package tutorials

import (
    "os/exec"
    "strings"
)

type CommandOutput struct {
    message  []string
    errorcode int
}


func execCommand(cmd []string) CommandOutput {

   // cmdArray := strings.Split(string(cmd),string(32))
    s := exec.Command(cmd[0], cmd[1:]...)
	
    stdout, err := s.Output()
    if err != nil {
        return CommandOutput{strings.Split(err.Error(),string(10)),-1}
    }

    return CommandOutput{strings.Split(string(stdout),string(10)),0}
}

