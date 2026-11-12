package deploy

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestComposeInterpolationUsesRuntimePasswordOnly(t *testing.T) {
	dir := t.TempDir()
	settings := filepath.Join(dir, "settings.env")
	database := filepath.Join(dir, "database.env")
	if err := os.WriteFile(settings, []byte("POSTGRES_PORT=65432\nPOSTGRES_PASSWORD=stale\n"), 0600); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(database, []byte("POSTGRES_USER=app\nPOSTGRES_PASSWORD='value$with#symbols'\n"), 0600); err != nil {
		t.Fatal(err)
	}
	config := Config{InfrastructureEnvFile: settings, DatabaseEnvFile: database}
	if err := writeComposeInterpolationEnv(&config, dir); err != nil {
		t.Fatal(err)
	}
	resolved, err := os.ReadFile(config.InfrastructureEnvFile)
	if err != nil {
		t.Fatal(err)
	}
	if strings.Count(string(resolved), "POSTGRES_PASSWORD=") != 1 || !strings.Contains(string(resolved), "POSTGRES_PASSWORD='value$with#symbols'\n") {
		t.Fatal("runtime settings did not preserve a single quoted database password")
	}
	original, err := os.ReadFile(settings)
	if err != nil || !strings.Contains(string(original), "POSTGRES_PASSWORD=stale") {
		t.Fatal("persistent settings were modified")
	}
	info, err := os.Stat(config.InfrastructureEnvFile)
	if err != nil || info.Mode().Perm() != 0600 {
		t.Fatal("runtime settings are not private")
	}
}

func TestComposeInterpolationRejectsAmbiguousPassword(t *testing.T) {
	for _, input := range []string{"POSTGRES_USER=app\n", "POSTGRES_PASSWORD=\n", "POSTGRES_PASSWORD=a\nPOSTGRES_PASSWORD=b\n"} {
		t.Run(input, func(t *testing.T) {
			dir := t.TempDir()
			settings, database := filepath.Join(dir, "settings.env"), filepath.Join(dir, "database.env")
			if err := os.WriteFile(settings, []byte("POSTGRES_PORT=65432\n"), 0600); err != nil {
				t.Fatal(err)
			}
			if err := os.WriteFile(database, []byte(input), 0600); err != nil {
				t.Fatal(err)
			}
			config := Config{InfrastructureEnvFile: settings, DatabaseEnvFile: database}
			if err := writeComposeInterpolationEnv(&config, dir); err == nil {
				t.Fatal("expected failure for a missing, empty, or duplicate password")
			}
		})
	}
}
