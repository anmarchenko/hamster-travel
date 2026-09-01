package main

import (
	"context"
	"errors"
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/anmarchenko/hamster-travel/deployment/internal/deploy"
)

func main() {
	log.SetFlags(0)
	log.SetPrefix("hamster-deploy: ")

	if err := run(); err != nil {
		log.Printf("ERROR: %v", err)
		os.Exit(1)
	}
}

func run() error {
	if len(os.Args) < 2 {
		return usageError()
	}

	config, err := deploy.ConfigFromEnvironment()
	if err != nil {
		return err
	}

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	d := deploy.New(config, deploy.ExecRunner{Log: log.Default()})

	switch os.Args[1] {
	case "deploy":
		if len(os.Args) != 2 {
			return usageError()
		}
		return d.Deploy(ctx)
	case "rollback":
		if len(os.Args) != 3 {
			return usageError()
		}
		return d.Rollback(ctx, os.Args[2])
	case "status":
		if len(os.Args) != 2 {
			return usageError()
		}
		return d.Status(ctx)
	case "releases":
		if len(os.Args) != 2 {
			return usageError()
		}
		return d.Releases(ctx)
	case "help", "-h", "--help":
		fmt.Fprint(os.Stdout, usage())
		return nil
	default:
		return usageError()
	}
}

func usageError() error {
	return errors.New(usage())
}

func usage() string {
	return `usage: hamster-deploy <command>

Commands:
  deploy               Build, verify, and deploy the current source tree
  rollback <release>   Switch to an existing release and verify it
  status               Show the production Compose services and image
  releases             List locally available production images
`
}
