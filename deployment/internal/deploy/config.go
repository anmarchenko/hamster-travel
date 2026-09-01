package deploy

import (
	"fmt"
	"os"
	"path/filepath"
	"strconv"
	"time"
)

const (
	defaultSourceDir      = "/home/marvin/Projects/hamster-travel"
	defaultInfrastructure = "/home/marvin/Work/hamster-travel-production"
)

// Config contains the machine-local production contract. Every value can be
// overridden for tests or a future move to another host without recompiling.
type Config struct {
	SourceDir             string
	InfrastructureDir     string
	ComposeFile           string
	AppEnvFile            string
	DatabaseEnvFile       string
	InfrastructureEnvFile string
	BackupMarker          string
	LockFile              string
	ImageRepository       string
	DatabaseContainer     string
	NetworkInterface      string
	RequiredAddress       string
	LocalHealthURL        string
	PublicHealthURL       string
	HealthTimeout         time.Duration
	MaxBackupAge          time.Duration
	DockerBinary          string
	GitBinary             string
}

func ConfigFromEnvironment() (Config, error) {
	sourceDir := envOrDefault("HAMSTER_DEPLOY_SOURCE_DIR", defaultSourceDir)
	infrastructureDir := envOrDefault("HAMSTER_DEPLOY_INFRA_DIR", defaultInfrastructure)

	healthTimeout, err := durationFromEnvironment("HAMSTER_DEPLOY_HEALTH_TIMEOUT", 90*time.Second)
	if err != nil {
		return Config{}, err
	}
	maxBackupAge, err := durationFromEnvironment("HAMSTER_DEPLOY_MAX_BACKUP_AGE", 24*time.Hour)
	if err != nil {
		return Config{}, err
	}

	return Config{
		SourceDir:             sourceDir,
		InfrastructureDir:     infrastructureDir,
		ComposeFile:           envOrDefault("HAMSTER_DEPLOY_COMPOSE_FILE", filepath.Join(sourceDir, "deployment/compose.yaml")),
		AppEnvFile:            envOrDefault("HAMSTER_DEPLOY_APP_ENV_FILE", filepath.Join(infrastructureDir, "app.env")),
		DatabaseEnvFile:       envOrDefault("HAMSTER_DEPLOY_DATABASE_ENV_FILE", filepath.Join(infrastructureDir, "database.env")),
		InfrastructureEnvFile: envOrDefault("HAMSTER_DEPLOY_INFRA_ENV_FILE", filepath.Join(infrastructureDir, ".env")),
		BackupMarker:          envOrDefault("HAMSTER_DEPLOY_BACKUP_MARKER", filepath.Join(infrastructureDir, "backups/.last-successful-backup")),
		LockFile:              envOrDefault("HAMSTER_DEPLOY_LOCK_FILE", "/run/lock/hamster-travel-deploy.lock"),
		ImageRepository:       envOrDefault("HAMSTER_DEPLOY_IMAGE", "hamster-travel-production"),
		DatabaseContainer:     envOrDefault("HAMSTER_DEPLOY_DATABASE_CONTAINER", "hamster-travel-production-db"),
		NetworkInterface:      envOrDefault("HAMSTER_DEPLOY_NETWORK_INTERFACE", "enp1s0"),
		RequiredAddress:       envOrDefault("HAMSTER_DEPLOY_REQUIRED_ADDRESS", "192.168.4.90"),
		LocalHealthURL:        envOrDefault("HAMSTER_DEPLOY_LOCAL_HEALTH_URL", "http://127.0.0.1:4400/up"),
		PublicHealthURL:       envOrDefault("HAMSTER_DEPLOY_PUBLIC_HEALTH_URL", "https://hamster-travel.tail920074.ts.net/up"),
		HealthTimeout:         healthTimeout,
		MaxBackupAge:          maxBackupAge,
		DockerBinary:          envOrDefault("HAMSTER_DEPLOY_DOCKER", "/usr/bin/docker"),
		GitBinary:             envOrDefault("HAMSTER_DEPLOY_GIT", "/usr/bin/git"),
	}, nil
}

func envOrDefault(name, fallback string) string {
	if value := os.Getenv(name); value != "" {
		return value
	}
	return fallback
}

func durationFromEnvironment(name string, fallback time.Duration) (time.Duration, error) {
	raw := os.Getenv(name)
	if raw == "" {
		return fallback, nil
	}

	value, err := time.ParseDuration(raw)
	if err != nil {
		return 0, fmt.Errorf("parse %s=%s: %w", name, strconv.Quote(raw), err)
	}
	if value <= 0 {
		return 0, fmt.Errorf("%s must be positive", name)
	}
	return value, nil
}
