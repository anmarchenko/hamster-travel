package deploy

import (
	"context"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

const productionSecretsDir = "/etc/hamster-travel/credentials"

// PrepareProductionSecrets supplies the default production env files for this
// invocation. Explicit overrides continue to work for recovery and testing.
func PrepareProductionSecrets(ctx context.Context, config *Config) (func(), error) {
	noop := func() {}
	if os.Geteuid() != 0 || config.InfrastructureDir != defaultInfrastructure {
		return noop, nil
	}
	if _, err := os.Stat(filepath.Join(productionSecretsDir, "op.json")); err != nil {
		return nil, fmt.Errorf("read production 1Password references: %w", err)
	}
	return prepareOnePasswordSecrets(ctx, config)
}

func prepareOnePasswordSecrets(ctx context.Context, config *Config) (func(), error) {
	dir, err := os.MkdirTemp("/run", "hamster-travel-deploy-*")
	if err != nil {
		return nil, fmt.Errorf("create production runtime directory: %w", err)
	}
	cleanup := func() { _ = os.RemoveAll(dir) }
	command := exec.CommandContext(ctx, "/usr/local/libexec/hamster-production-credentials", "materialize", "deploy", dir)
	command.Env = []string{"PATH=/usr/bin"}
	if err := command.Run(); err != nil {
		cleanup()
		return nil, fmt.Errorf("resolve production inputs from 1Password: %w", err)
	}
	defaultAppEnv := config.AppEnvFile == filepath.Join(config.InfrastructureDir, "app.env")
	if defaultAppEnv {
		config.AppEnvFile = filepath.Join(dir, "app.env")
	}
	if config.DatabaseEnvFile == filepath.Join(config.InfrastructureDir, "database.env") {
		config.DatabaseEnvFile = filepath.Join(dir, "database.env")
	}
	if defaultAppEnv {
		if err := writeComposeInterpolationEnv(config, dir); err != nil {
			cleanup()
			return nil, err
		}
	}
	return cleanup, nil
}

// Compose expands DATABASE_URL in app.env using its project-level env file.
// Supply the database password for that expansion only in the runtime copy.
func writeComposeInterpolationEnv(config *Config, dir string) error {
	settings, err := os.ReadFile(config.InfrastructureEnvFile)
	if err != nil {
		return fmt.Errorf("read Compose settings: %w", err)
	}
	databaseEnv, err := os.ReadFile(config.DatabaseEnvFile)
	if err != nil {
		return fmt.Errorf("read database credentials: %w", err)
	}
	var password string
	for line := range strings.SplitSeq(string(databaseEnv), "\n") {
		line = strings.TrimPrefix(strings.TrimSpace(line), "export ")
		name, value, found := strings.Cut(line, "=")
		if found && strings.TrimSpace(name) == "POSTGRES_PASSWORD" {
			if password != "" || strings.TrimSpace(value) == "" {
				return errors.New("expected a single nonempty POSTGRES_PASSWORD in the database credentials")
			}
			password = value
		}
	}
	if password == "" {
		return errors.New("missing POSTGRES_PASSWORD in the database credentials")
	}
	// Drop any old assignment while the original settings file is still in use.
	var result strings.Builder
	for line := range strings.SplitSeq(string(settings), "\n") {
		name, _, _ := strings.Cut(strings.TrimPrefix(strings.TrimSpace(line), "export "), "=")
		if strings.TrimSpace(name) != "POSTGRES_PASSWORD" {
			result.WriteString(line + "\n")
		}
	}
	result.WriteString("POSTGRES_PASSWORD=" + password + "\n")
	file := filepath.Join(dir, "compose.env")
	if err := os.WriteFile(file, []byte(result.String()), 0600); err != nil {
		return err
	}
	config.InfrastructureEnvFile = file
	return nil
}
