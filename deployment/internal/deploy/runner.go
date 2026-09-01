package deploy

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"log"
	"os"
	"os/exec"
	"strings"
)

type Runner interface {
	Run(ctx context.Context, env map[string]string, name string, args ...string) error
	Output(ctx context.Context, env map[string]string, name string, args ...string) (string, error)
}

type ExecRunner struct {
	Log *log.Logger
}

func (r ExecRunner) Run(ctx context.Context, env map[string]string, name string, args ...string) error {
	r.logCommand(name, args)
	command := exec.CommandContext(ctx, name, args...)
	command.Env = commandEnvironment(env)
	command.Stdout = os.Stdout
	command.Stderr = os.Stderr
	if err := command.Run(); err != nil {
		return fmt.Errorf("run %s: %w", commandString(name, args), err)
	}
	return nil
}

func (r ExecRunner) Output(ctx context.Context, env map[string]string, name string, args ...string) (string, error) {
	r.logCommand(name, args)
	command := exec.CommandContext(ctx, name, args...)
	command.Env = commandEnvironment(env)
	var stdout bytes.Buffer
	var stderr bytes.Buffer
	command.Stdout = &stdout
	command.Stderr = io.MultiWriter(os.Stderr, &stderr)
	if err := command.Run(); err != nil {
		message := strings.TrimSpace(stderr.String())
		if message != "" {
			return "", fmt.Errorf("run %s: %w: %s", commandString(name, args), err, message)
		}
		return "", fmt.Errorf("run %s: %w", commandString(name, args), err)
	}
	return strings.TrimSpace(stdout.String()), nil
}

func (r ExecRunner) logCommand(name string, args []string) {
	if r.Log != nil {
		r.Log.Printf("running %s", commandString(name, args))
	}
}

func commandEnvironment(overrides map[string]string) []string {
	env := os.Environ()
	for name, value := range overrides {
		env = append(env, name+"="+value)
	}
	return env
}

func commandString(name string, args []string) string {
	return strings.Join(append([]string{name}, args...), " ")
}
