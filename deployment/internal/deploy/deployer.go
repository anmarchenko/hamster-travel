package deploy

import (
	"bufio"
	"context"
	"errors"
	"fmt"
	"net"
	"os"
	"strings"
	"time"
)

const productionImageLabel = "com.hamster-travel.production=true"

var requiredAppEnvironment = []string{
	"DATABASE_URL",
	"SECRET_KEY_BASE",
	"AWS_ACCESS_KEY_ID",
	"AWS_SECRET_ACCESS_KEY",
	"OPEN_EXCHANGE_RATES_APP_ID",
	"MAPBOX_ACCESS_TOKEN",
}

var requiredDatabaseEnvironment = []string{
	"POSTGRES_USER",
	"POSTGRES_PASSWORD",
	"POSTGRES_DB",
}

type Deployer struct {
	Config         Config
	Runner         Runner
	Health         HealthChecker
	Now            func() time.Time
	EffectiveUID   func() int
	AddressPresent func(interfaceName, address string) error
}

func New(config Config, runner Runner) *Deployer {
	return &Deployer{
		Config:         config,
		Runner:         runner,
		Health:         HTTPHealthChecker{},
		Now:            time.Now,
		EffectiveUID:   os.Geteuid,
		AddressPresent: requireInterfaceAddress,
	}
}

func (d *Deployer) Deploy(ctx context.Context) error {
	if err := d.requireRoot(); err != nil {
		return err
	}
	lock, err := acquireLock(d.Config.LockFile)
	if err != nil {
		return err
	}
	defer func() { _ = lock.Close() }()

	if err := d.preflight(ctx, true); err != nil {
		return fmt.Errorf("preflight failed: %w", err)
	}

	version, revision, err := d.releaseIdentity(ctx)
	if err != nil {
		return err
	}
	candidateImage := d.Config.ImageRepository + ":" + version
	previousImage, err := d.currentImage(ctx)
	if err != nil {
		return fmt.Errorf("identify current production image: %w", err)
	}
	if previousImage == candidateImage {
		return fmt.Errorf("candidate image %s is already running; set a unique release or change the source tree", candidateImage)
	}

	fmt.Printf("Building %s while %s continues serving traffic.\n", candidateImage, previousImage)
	if err := d.build(ctx, candidateImage, version, revision); err != nil {
		return fmt.Errorf("build candidate image: %w", err)
	}
	if err := d.runOneOff(ctx, candidateImage, "migrate"); err != nil {
		return fmt.Errorf("candidate migration failed before cutover: %w", err)
	}
	if err := d.runOneOff(ctx, candidateImage, "verify-storage"); err != nil {
		return fmt.Errorf("candidate storage verification failed before cutover: %w", err)
	}

	fmt.Printf("Switching production from %s to %s.\n", previousImage, candidateImage)
	if err := d.switchAndVerify(ctx, candidateImage); err != nil {
		fmt.Fprintf(os.Stderr, "Candidate failed after cutover; restoring %s.\n", previousImage)
		recoveryCtx, cancelRecovery := d.recoveryContext(ctx)
		defer cancelRecovery()
		rollbackErr := d.switchAndVerify(recoveryCtx, previousImage)
		if rollbackErr != nil {
			return fmt.Errorf("deploy %s failed: %w; automatic restoration of %s also failed: %v", candidateImage, err, previousImage, rollbackErr)
		}
		return fmt.Errorf("deploy %s failed and %s was restored: %w", candidateImage, previousImage, err)
	}

	if err := d.Runner.Run(ctx, nil, d.Config.DockerBinary, "image", "tag", candidateImage, d.Config.ImageRepository+":current"); err != nil {
		return fmt.Errorf("deployment is healthy, but tagging current release failed: %w", err)
	}

	fmt.Printf("Deployment successful: %s\n", candidateImage)
	return nil
}

func (d *Deployer) Rollback(ctx context.Context, release string) error {
	if err := d.requireRoot(); err != nil {
		return err
	}
	lock, err := acquireLock(d.Config.LockFile)
	if err != nil {
		return err
	}
	defer func() { _ = lock.Close() }()

	if err := d.preflight(ctx, false); err != nil {
		return fmt.Errorf("preflight failed: %w", err)
	}

	targetImage := release
	if !strings.Contains(release, ":") {
		targetImage = d.Config.ImageRepository + ":" + release
	}
	if _, err := d.Runner.Output(ctx, nil, d.Config.DockerBinary, "image", "inspect", targetImage, "--format", "{{.Id}}"); err != nil {
		return fmt.Errorf("rollback image %s is not available locally: %w", targetImage, err)
	}

	previousImage, err := d.currentImage(ctx)
	if err != nil {
		return fmt.Errorf("identify current production image: %w", err)
	}
	if targetImage == previousImage {
		return fmt.Errorf("rollback target %s is already running", targetImage)
	}

	fmt.Printf("Rolling back production from %s to %s. Database migrations are not reversed.\n", previousImage, targetImage)
	if err := d.switchAndVerify(ctx, targetImage); err != nil {
		fmt.Fprintf(os.Stderr, "Rollback target failed; restoring %s.\n", previousImage)
		recoveryCtx, cancelRecovery := d.recoveryContext(ctx)
		defer cancelRecovery()
		restoreErr := d.switchAndVerify(recoveryCtx, previousImage)
		if restoreErr != nil {
			return fmt.Errorf("rollback to %s failed: %w; restoration of %s also failed: %v", targetImage, err, previousImage, restoreErr)
		}
		return fmt.Errorf("rollback to %s failed and %s was restored: %w", targetImage, previousImage, err)
	}

	if err := d.Runner.Run(ctx, nil, d.Config.DockerBinary, "image", "tag", targetImage, d.Config.ImageRepository+":current"); err != nil {
		return fmt.Errorf("rollback is healthy, but tagging current release failed: %w", err)
	}
	fmt.Printf("Rollback successful: %s\n", targetImage)
	return nil
}

func (d *Deployer) Status(ctx context.Context) error {
	if err := d.requireRoot(); err != nil {
		return err
	}
	if err := d.Runner.Run(ctx, d.composeEnvironment(d.Config.ImageRepository+":current"), d.Config.DockerBinary, d.composeArgs("ps")...); err != nil {
		return err
	}
	image, err := d.currentImage(ctx)
	if err != nil {
		return err
	}
	fmt.Printf("Running image: %s\n", image)
	return nil
}

func (d *Deployer) Releases(ctx context.Context) error {
	if err := d.requireRoot(); err != nil {
		return err
	}
	return d.Runner.Run(
		ctx,
		nil,
		d.Config.DockerBinary,
		"image", "ls",
		"--filter", "label="+productionImageLabel,
		"--format", "table {{.Repository}}\t{{.Tag}}\t{{.CreatedSince}}\t{{.Size}}\t{{.ID}}",
	)
}

func (d *Deployer) preflight(ctx context.Context, requireBackup bool) error {
	for _, path := range []string{
		d.Config.SourceDir,
		d.Config.InfrastructureDir,
		d.Config.ComposeFile,
		d.Config.AppEnvFile,
		d.Config.DatabaseEnvFile,
		d.Config.InfrastructureEnvFile,
	} {
		if _, err := os.Stat(path); err != nil {
			return fmt.Errorf("required path %s: %w", path, err)
		}
	}
	if err := validateEnvironmentFile(d.Config.AppEnvFile, requiredAppEnvironment); err != nil {
		return err
	}
	if err := validateEnvironmentFile(d.Config.DatabaseEnvFile, requiredDatabaseEnvironment); err != nil {
		return err
	}
	if err := validateFileMode(d.Config.InfrastructureEnvFile, 0o600); err != nil {
		return err
	}
	if requireBackup {
		if err := validateBackupMarker(d.Config.BackupMarker, d.Now(), d.Config.MaxBackupAge); err != nil {
			return err
		}
	}
	if err := d.AddressPresent(d.Config.NetworkInterface, d.Config.RequiredAddress); err != nil {
		return err
	}
	if err := d.Runner.Run(ctx, nil, d.Config.DockerBinary, "info"); err != nil {
		return fmt.Errorf("Docker is unavailable: %w", err)
	}
	composeEnv := d.composeEnvironment(d.Config.ImageRepository + ":current")
	if err := d.Runner.Run(ctx, composeEnv, d.Config.DockerBinary, d.composeArgs("config", "--quiet")...); err != nil {
		return fmt.Errorf("invalid production Compose configuration: %w", err)
	}
	databaseHealth, err := d.Runner.Output(ctx, nil, d.Config.DockerBinary, "inspect", d.Config.DatabaseContainer, "--format", "{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}")
	if err != nil {
		return fmt.Errorf("inspect production database: %w", err)
	}
	if databaseHealth != "healthy" {
		return fmt.Errorf("production database is %q, expected healthy", databaseHealth)
	}
	if _, err := d.currentImage(ctx); err != nil {
		return fmt.Errorf("production web service is not managed by Compose: %w", err)
	}
	return nil
}

func (d *Deployer) build(ctx context.Context, image, version, revision string) error {
	return d.Runner.Run(
		ctx,
		nil,
		d.Config.DockerBinary,
		"build",
		"--label", productionImageLabel,
		"--label", "com.hamster-travel.version="+version,
		"--label", "org.opencontainers.image.revision="+revision,
		"--tag", image,
		d.Config.SourceDir,
	)
}

func (d *Deployer) runOneOff(ctx context.Context, image, service string) error {
	return d.Runner.Run(
		ctx,
		d.composeEnvironment(image),
		d.Config.DockerBinary,
		d.composeArgs("--profile", "ops", "run", "--rm", "--no-deps", service)...,
	)
}

func (d *Deployer) switchAndVerify(ctx context.Context, image string) error {
	env := d.composeEnvironment(image)
	if err := d.Runner.Run(
		ctx,
		env,
		d.Config.DockerBinary,
		d.composeArgs("up", "--detach", "--no-deps", "--force-recreate", "--wait", "--wait-timeout", durationSeconds(d.Config.HealthTimeout), "web")...,
	); err != nil {
		return fmt.Errorf("Compose could not start healthy image %s: %w", image, err)
	}
	return d.verifyExternalHealth(ctx)
}

func (d *Deployer) verifyExternalHealth(ctx context.Context) error {
	if err := d.Health.Wait(ctx, d.Config.LocalHealthURL, d.Config.HealthTimeout); err != nil {
		return err
	}
	return d.Health.Wait(ctx, d.Config.PublicHealthURL, d.Config.HealthTimeout)
}

func (d *Deployer) currentImage(ctx context.Context) (string, error) {
	env := d.composeEnvironment(d.Config.ImageRepository + ":current")
	containerID, err := d.Runner.Output(ctx, env, d.Config.DockerBinary, d.composeArgs("ps", "--quiet", "web")...)
	if err != nil {
		return "", err
	}
	if containerID == "" {
		return "", errors.New("Compose web container does not exist")
	}
	image, err := d.Runner.Output(ctx, nil, d.Config.DockerBinary, "inspect", containerID, "--format", "{{.Config.Image}}")
	if err != nil {
		return "", err
	}
	if image == "" {
		return "", errors.New("running web container has no image name")
	}
	return image, nil
}

func (d *Deployer) releaseIdentity(ctx context.Context) (version string, revision string, err error) {
	revision, err = d.Runner.Output(ctx, nil, d.Config.GitBinary, "-C", d.Config.SourceDir, "rev-parse", "--short=12", "HEAD")
	if err != nil {
		return "", "", fmt.Errorf("read Git revision: %w", err)
	}
	dirty, err := d.Runner.Output(ctx, nil, d.Config.GitBinary, "-C", d.Config.SourceDir, "status", "--porcelain")
	if err != nil {
		return "", "", fmt.Errorf("read Git worktree status: %w", err)
	}
	version = "local-" + d.Now().UTC().Format("20060102150405") + "-" + revision
	if dirty != "" {
		version += "-dirty"
	}
	return version, revision, nil
}

func (d *Deployer) composeEnvironment(image string) map[string]string {
	return map[string]string{
		"HAMSTER_TRAVEL_IMAGE":             image,
		"HAMSTER_TRAVEL_APP_ENV_FILE":      d.Config.AppEnvFile,
		"HAMSTER_TRAVEL_DATABASE_ENV_FILE": d.Config.DatabaseEnvFile,
	}
}

func (d *Deployer) composeArgs(args ...string) []string {
	prefix := []string{
		"compose",
		"--project-directory", d.Config.InfrastructureDir,
		"--env-file", d.Config.InfrastructureEnvFile,
		"--file", d.Config.ComposeFile,
	}
	return append(prefix, args...)
}

func (d *Deployer) requireRoot() error {
	if d.EffectiveUID() != 0 {
		return errors.New("this command needs Docker root access; run it with sudo (the user does not need Docker-group membership)")
	}
	return nil
}

func validateEnvironmentFile(path string, required []string) error {
	if err := validateFileMode(path, 0o600); err != nil {
		return err
	}

	file, err := os.Open(path)
	if err != nil {
		return fmt.Errorf("open environment file %s: %w", path, err)
	}
	defer func() { _ = file.Close() }()

	values := make(map[string]bool)
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		line = strings.TrimPrefix(line, "export ")
		name, value, found := strings.Cut(line, "=")
		if !found {
			continue
		}
		name = strings.TrimSpace(name)
		value = strings.TrimSpace(value)
		if name != "" && value != "" && value != `""` && value != "''" {
			values[name] = true
		}
	}
	if err := scanner.Err(); err != nil {
		return fmt.Errorf("read environment file %s: %w", path, err)
	}

	var missing []string
	for _, name := range required {
		if !values[name] {
			missing = append(missing, name)
		}
	}
	if len(missing) > 0 {
		return fmt.Errorf("environment file %s is missing non-empty keys: %s", path, strings.Join(missing, ", "))
	}
	return nil
}

func validateFileMode(path string, expected os.FileMode) error {
	info, err := os.Stat(path)
	if err != nil {
		return fmt.Errorf("stat sensitive file %s: %w", path, err)
	}
	if info.Mode().Perm() != expected {
		return fmt.Errorf("sensitive file %s has mode %04o; expected %04o", path, info.Mode().Perm(), expected)
	}
	return nil
}

func validateBackupMarker(path string, now time.Time, maxAge time.Duration) error {
	info, err := os.Stat(path)
	if err != nil {
		return fmt.Errorf("verified backup marker %s: %w", path, err)
	}
	age := now.Sub(info.ModTime())
	if age < 0 {
		return fmt.Errorf("verified backup marker %s is dated in the future", path)
	}
	if age > maxAge {
		return fmt.Errorf("last verified production backup is %s old; maximum allowed age is %s", age.Round(time.Minute), maxAge)
	}
	return nil
}

func requireInterfaceAddress(interfaceName, requiredAddress string) error {
	interfaceInfo, err := net.InterfaceByName(interfaceName)
	if err != nil {
		return fmt.Errorf("find required network interface %s: %w", interfaceName, err)
	}
	addresses, err := interfaceInfo.Addrs()
	if err != nil {
		return fmt.Errorf("list addresses for %s: %w", interfaceName, err)
	}
	for _, address := range addresses {
		if strings.SplitN(address.String(), "/", 2)[0] == requiredAddress {
			return nil
		}
	}
	return fmt.Errorf("required production address %s is not assigned to %s", requiredAddress, interfaceName)
}

func durationSeconds(duration time.Duration) string {
	seconds := int64(duration.Round(time.Second) / time.Second)
	if seconds < 1 {
		seconds = 1
	}
	return fmt.Sprintf("%d", seconds)
}

func (d *Deployer) recoveryContext(ctx context.Context) (context.Context, context.CancelFunc) {
	return context.WithTimeout(context.WithoutCancel(ctx), 2*d.Config.HealthTimeout+30*time.Second)
}
