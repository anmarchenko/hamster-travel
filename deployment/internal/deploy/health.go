package deploy

import (
	"context"
	"fmt"
	"io"
	"net/http"
	"time"
)

type HealthChecker interface {
	Wait(ctx context.Context, url string, timeout time.Duration) error
}

type HTTPHealthChecker struct {
	Client       *http.Client
	PollInterval time.Duration
}

func (checker HTTPHealthChecker) Wait(ctx context.Context, url string, timeout time.Duration) error {
	client := checker.Client
	if client == nil {
		client = &http.Client{Timeout: 10 * time.Second}
	}
	pollInterval := checker.PollInterval
	if pollInterval <= 0 {
		pollInterval = 2 * time.Second
	}

	deadline := time.Now().Add(timeout)
	var lastErr error
	for {
		request, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
		if err != nil {
			return fmt.Errorf("create health request for %s: %w", url, err)
		}

		response, err := client.Do(request)
		if err == nil {
			_, _ = io.Copy(io.Discard, response.Body)
			_ = response.Body.Close()
			if response.StatusCode == http.StatusOK {
				return nil
			}
			lastErr = fmt.Errorf("HTTP %d", response.StatusCode)
		} else {
			lastErr = err
		}

		if time.Now().Add(pollInterval).After(deadline) {
			return fmt.Errorf("health check %s did not return HTTP 200 within %s: %w", url, timeout, lastErr)
		}

		select {
		case <-ctx.Done():
			return fmt.Errorf("health check %s interrupted: %w", url, ctx.Err())
		case <-time.After(pollInterval):
		}
	}
}
