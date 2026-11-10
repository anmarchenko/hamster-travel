package deploy

import (
	"context"
	"encoding/base64"
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
	manifest := filepath.Join(productionSecretsDir, "deploy.toml")
	if _, err := os.Stat(manifest); errors.Is(err, os.ErrNotExist) {
		return noop, nil
	} else if err != nil {
		return nil, fmt.Errorf("stat production credential manifest: %w", err)
	}

	dir, err := os.MkdirTemp("/run", "hamster-travel-deploy-")
	if err != nil {
		return nil, fmt.Errorf("create production runtime directory: %w", err)
	}
	cleanup := func() { _ = os.RemoveAll(dir) }
	if err := materializeProductionSecrets(ctx, config, dir, manifest); err != nil {
		cleanup()
		return nil, err
	}
	return cleanup, nil
}

func materializeProductionSecrets(ctx context.Context, config *Config, dir, manifest string) error {
	identity := filepath.Join(dir, "age-identity")
	decryption := exec.CommandContext(ctx, "/usr/bin/systemd-creds", "--name=age-identity", "decrypt",
		filepath.Join(productionSecretsDir, "deploy.cred"), "-")
	if err := writeRuntimeCredential(identity, decryption, false); err != nil {
		return err
	}
	defer os.Remove(identity)

	defaultAppEnv := config.AppEnvFile == filepath.Join(config.InfrastructureDir, "app.env")
	for _, input := range []struct {
		name, key string
		path      *string
	}{
		{"app.env", "APP_ENV", &config.AppEnvFile},
		{"database.env", "DATABASE_ENV", &config.DatabaseEnvFile},
	} {
		if *input.path != filepath.Join(config.InfrastructureDir, input.name) {
			continue
		}
		file := filepath.Join(dir, input.name)
		command := exec.CommandContext(ctx, "/usr/local/bin/fnox", "-c", manifest,
			"--no-daemon", "--non-interactive", "--if-missing", "error", "get", input.key)
		command.Dir = productionSecretsDir
		command.Env = []string{"PATH=/usr/bin", "FNOX_CONFIG_DIR=/nonexistent", "FNOX_AGE_KEY_FILE=" + identity}
		if err := writeRuntimeCredential(file, command, true); err != nil {
			return err
		}
		*input.path = file
	}
	if defaultAppEnv {
		return writeComposeInterpolationEnv(config, dir)
	}
	return nil
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

func writeRuntimeCredential(path string, command *exec.Cmd, encoded bool) error {
	data, err := command.Output()
	if err != nil {
		return fmt.Errorf("resolve %s: %w", filepath.Base(path), err)
	}
	if encoded {
		data, err = base64.StdEncoding.DecodeString(string(data))
		if err != nil {
			return fmt.Errorf("invalid encoded production credential: %s", filepath.Base(path))
		}
	}
	if len(data) == 0 {
		return fmt.Errorf("empty production credential: %s", filepath.Base(path))
	}
	return os.WriteFile(path, data, 0600)
}
