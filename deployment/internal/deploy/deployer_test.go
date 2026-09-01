package deploy

import (
	"context"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"testing"
	"time"
)

type recordedCall struct {
	kind string
	env  map[string]string
	name string
	args []string
}

type fakeRunner struct {
	calls       []recordedCall
	failRun     func(name string, args []string) error
	webImage    string
	containerID string
}

func (runner *fakeRunner) Run(_ context.Context, env map[string]string, name string, args ...string) error {
	runner.calls = append(runner.calls, recordedCall{kind: "run", env: cloneMap(env), name: name, args: append([]string(nil), args...)})
	if runner.failRun != nil {
		return runner.failRun(name, args)
	}
	return nil
}

func (runner *fakeRunner) Output(_ context.Context, env map[string]string, name string, args ...string) (string, error) {
	runner.calls = append(runner.calls, recordedCall{kind: "output", env: cloneMap(env), name: name, args: append([]string(nil), args...)})
	joined := strings.Join(args, " ")
	switch {
	case strings.Contains(joined, "rev-parse --short=12 HEAD"):
		return "abc123def456", nil
	case strings.Contains(joined, "status --porcelain"):
		return "", nil
	case strings.Contains(joined, "compose") && strings.Contains(joined, "ps --quiet web"):
		if runner.containerID == "" {
			return "web-container", nil
		}
		return runner.containerID, nil
	case strings.Contains(joined, "inspect hamster-travel-production-db"):
		return "healthy", nil
	case strings.Contains(joined, "inspect web-container"):
		return runner.webImage, nil
	case strings.Contains(joined, "image inspect"):
		return "sha256:rollback", nil
	default:
		return "", fmt.Errorf("unexpected output command: %s %s", name, joined)
	}
}

type fakeHealthChecker struct {
	errors []error
	urls   []string
}

func (checker *fakeHealthChecker) Wait(_ context.Context, url string, _ time.Duration) error {
	checker.urls = append(checker.urls, url)
	if len(checker.errors) == 0 {
		return nil
	}
	err := checker.errors[0]
	checker.errors = checker.errors[1:]
	return err
}

func TestDeployRunsChecksBeforeSwitch(t *testing.T) {
	deployer, runner, health := testDeployer(t)

	if err := deployer.Deploy(context.Background()); err != nil {
		t.Fatalf("Deploy() error = %v", err)
	}

	operations := significantOperations(runner.calls)
	want := []string{
		"build:hamster-travel-production:local-20260830120000-abc123def456",
		"run:migrate:hamster-travel-production:local-20260830120000-abc123def456",
		"run:verify-storage:hamster-travel-production:local-20260830120000-abc123def456",
		"switch:hamster-travel-production:local-20260830120000-abc123def456",
		"tag:hamster-travel-production:local-20260830120000-abc123def456",
	}
	if !reflect.DeepEqual(operations, want) {
		t.Fatalf("significant operations = %#v, want %#v", operations, want)
	}
	if !reflect.DeepEqual(health.urls, []string{deployer.Config.LocalHealthURL, deployer.Config.PublicHealthURL}) {
		t.Fatalf("health URLs = %#v", health.urls)
	}
}

func TestDeployRestoresPreviousImageAfterPublicHealthFailure(t *testing.T) {
	deployer, runner, health := testDeployer(t)
	health.errors = []error{nil, errors.New("funnel unavailable"), nil, nil}

	err := deployer.Deploy(context.Background())
	if err == nil || !strings.Contains(err.Error(), "was restored") {
		t.Fatalf("Deploy() error = %v, want restoration error", err)
	}

	var switchedImages []string
	for _, operation := range significantOperations(runner.calls) {
		if strings.HasPrefix(operation, "switch:") {
			switchedImages = append(switchedImages, strings.TrimPrefix(operation, "switch:"))
		}
	}
	want := []string{
		"hamster-travel-production:local-20260830120000-abc123def456",
		"hamster-travel-production:previous",
	}
	if !reflect.DeepEqual(switchedImages, want) {
		t.Fatalf("switched images = %#v, want %#v", switchedImages, want)
	}
}

func TestDeployDoesNotSwitchWhenMigrationFails(t *testing.T) {
	deployer, runner, _ := testDeployer(t)
	runner.failRun = func(_ string, args []string) error {
		joined := strings.Join(args, " ")
		if strings.Contains(joined, "run --rm --no-deps migrate") {
			return errors.New("migration failed")
		}
		return nil
	}

	err := deployer.Deploy(context.Background())
	if err == nil || !strings.Contains(err.Error(), "migration failed before cutover") {
		t.Fatalf("Deploy() error = %v, want migration failure", err)
	}
	for _, operation := range significantOperations(runner.calls) {
		if strings.HasPrefix(operation, "switch:") {
			t.Fatalf("unexpected cutover after migration failure: %s", operation)
		}
	}
}

func TestRollbackRestoresCurrentImageWhenTargetFailsHealthCheck(t *testing.T) {
	deployer, runner, health := testDeployer(t)
	health.errors = []error{nil, errors.New("rollback target unavailable"), nil, nil}

	err := deployer.Rollback(context.Background(), "older")
	if err == nil || !strings.Contains(err.Error(), "was restored") {
		t.Fatalf("Rollback() error = %v, want restoration error", err)
	}

	var switchedImages []string
	for _, operation := range significantOperations(runner.calls) {
		if strings.HasPrefix(operation, "switch:") {
			switchedImages = append(switchedImages, strings.TrimPrefix(operation, "switch:"))
		}
	}
	want := []string{
		"hamster-travel-production:older",
		"hamster-travel-production:previous",
	}
	if !reflect.DeepEqual(switchedImages, want) {
		t.Fatalf("switched images = %#v, want %#v", switchedImages, want)
	}
}

func TestRecoveryContextSurvivesCallerCancellation(t *testing.T) {
	deployer, _, _ := testDeployer(t)
	parent, cancelParent := context.WithCancel(context.Background())
	cancelParent()

	recovery, cancelRecovery := deployer.recoveryContext(parent)
	defer cancelRecovery()
	if err := recovery.Err(); err != nil {
		t.Fatalf("recovery context inherited cancellation: %v", err)
	}
}

func TestValidateEnvironmentFileRejectsLoosePermissionsAndMissingValues(t *testing.T) {
	path := filepath.Join(t.TempDir(), "app.env")
	if err := os.WriteFile(path, []byte("DATABASE_URL=value\nSECRET_KEY_BASE=\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := validateEnvironmentFile(path, []string{"DATABASE_URL", "SECRET_KEY_BASE"}); err == nil || !strings.Contains(err.Error(), "expected 0600") {
		t.Fatalf("permission validation error = %v", err)
	}
	if err := os.Chmod(path, 0o600); err != nil {
		t.Fatal(err)
	}
	if err := validateEnvironmentFile(path, []string{"DATABASE_URL", "SECRET_KEY_BASE"}); err == nil || !strings.Contains(err.Error(), "SECRET_KEY_BASE") {
		t.Fatalf("required-key validation error = %v", err)
	}
}

func TestValidateBackupMarkerRejectsStaleBackup(t *testing.T) {
	path := filepath.Join(t.TempDir(), "marker")
	if err := os.WriteFile(path, []byte("ok\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	now := time.Date(2026, 8, 30, 12, 0, 0, 0, time.UTC)
	stale := now.Add(-25 * time.Hour)
	if err := os.Chtimes(path, stale, stale); err != nil {
		t.Fatal(err)
	}
	if err := validateBackupMarker(path, now, 24*time.Hour); err == nil || !strings.Contains(err.Error(), "maximum allowed age") {
		t.Fatalf("backup validation error = %v", err)
	}
}

func testDeployer(t *testing.T) (*Deployer, *fakeRunner, *fakeHealthChecker) {
	t.Helper()
	temporaryDir := t.TempDir()
	sourceDir := filepath.Join(temporaryDir, "source")
	infrastructureDir := filepath.Join(temporaryDir, "infra")
	if err := os.MkdirAll(sourceDir, 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.MkdirAll(filepath.Join(infrastructureDir, "backups"), 0o700); err != nil {
		t.Fatal(err)
	}
	composeFile := filepath.Join(sourceDir, "compose.yaml")
	if err := os.WriteFile(composeFile, []byte("services: {}\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	appEnvFile := filepath.Join(infrastructureDir, "app.env")
	infrastructureEnvFile := filepath.Join(infrastructureDir, ".env")
	databaseEnvFile := filepath.Join(infrastructureDir, "database.env")
	var appEnvironment strings.Builder
	for _, name := range requiredAppEnvironment {
		fmt.Fprintf(&appEnvironment, "%s=value\n", name)
	}
	if err := os.WriteFile(appEnvFile, []byte(appEnvironment.String()), 0o600); err != nil {
		t.Fatal(err)
	}
	infrastructureEnvironment := `POSTGRES_USER=value
POSTGRES_PASSWORD=value
POSTGRES_DB=value
SECRET_KEY_BASE=value
AWS_ACCESS_KEY_ID=value
AWS_SECRET_ACCESS_KEY=value
OPEN_EXCHANGE_RATES_APP_ID=value
MAPBOX_ACCESS_TOKEN=value
`
	if err := os.WriteFile(infrastructureEnvFile, []byte(infrastructureEnvironment), 0o600); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(databaseEnvFile, []byte("POSTGRES_USER=value\nPOSTGRES_PASSWORD=value\nPOSTGRES_DB=value\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	backupMarker := filepath.Join(infrastructureDir, "backups", ".last-successful-backup")
	if err := os.WriteFile(backupMarker, []byte("ok\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	now := time.Date(2026, 8, 30, 12, 0, 0, 0, time.UTC)
	if err := os.Chtimes(backupMarker, now.Add(-time.Hour), now.Add(-time.Hour)); err != nil {
		t.Fatal(err)
	}

	config := Config{
		SourceDir:             sourceDir,
		InfrastructureDir:     infrastructureDir,
		ComposeFile:           composeFile,
		AppEnvFile:            appEnvFile,
		DatabaseEnvFile:       databaseEnvFile,
		InfrastructureEnvFile: infrastructureEnvFile,
		BackupMarker:          backupMarker,
		LockFile:              filepath.Join(temporaryDir, "deploy.lock"),
		ImageRepository:       "hamster-travel-production",
		DatabaseContainer:     "hamster-travel-production-db",
		NetworkInterface:      "test0",
		RequiredAddress:       "192.0.2.10",
		LocalHealthURL:        "http://127.0.0.1:4400/up",
		PublicHealthURL:       "https://example.test/up",
		HealthTimeout:         90 * time.Second,
		MaxBackupAge:          24 * time.Hour,
		DockerBinary:          "/usr/bin/docker",
		GitBinary:             "/usr/bin/git",
	}
	runner := &fakeRunner{webImage: "hamster-travel-production:previous", containerID: "web-container"}
	health := &fakeHealthChecker{}
	deployer := New(config, runner)
	deployer.Health = health
	deployer.Now = func() time.Time { return now }
	deployer.EffectiveUID = func() int { return 0 }
	deployer.AddressPresent = func(_, _ string) error { return nil }
	return deployer, runner, health
}

func significantOperations(calls []recordedCall) []string {
	var operations []string
	for _, call := range calls {
		joined := strings.Join(call.args, " ")
		image := call.env["HAMSTER_TRAVEL_IMAGE"]
		switch {
		case call.kind == "run" && len(call.args) > 0 && call.args[0] == "build":
			for index, argument := range call.args {
				if argument == "--tag" && index+1 < len(call.args) {
					operations = append(operations, "build:"+call.args[index+1])
				}
			}
		case call.kind == "run" && strings.Contains(joined, "run --rm --no-deps migrate"):
			operations = append(operations, "run:migrate:"+image)
		case call.kind == "run" && strings.Contains(joined, "run --rm --no-deps verify-storage"):
			operations = append(operations, "run:verify-storage:"+image)
		case call.kind == "run" && strings.Contains(joined, "up --detach"):
			operations = append(operations, "switch:"+image)
		case call.kind == "run" && len(call.args) > 2 && call.args[0] == "image" && call.args[1] == "tag":
			operations = append(operations, "tag:"+call.args[2])
		}
	}
	return operations
}

func cloneMap(input map[string]string) map[string]string {
	if input == nil {
		return nil
	}
	output := make(map[string]string, len(input))
	for name, value := range input {
		output[name] = value
	}
	return output
}
