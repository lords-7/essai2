package main

import (
	"context"
	"fmt"
	"time"

	"golang.org/x/sync/errgroup"
)

var versions = []string{"24.04", "22.04", "20.04", "18.04"}

type Brew struct{}

// BaseContainer returns the container from homebrew's Dockerfile.
func (m *Brew) BaseContainer(src *Directory, version, commitSha, githubRepo, repoOwner, baseImageVersion string, brewVersion string) *Container {
	return src.DockerBuild(DirectoryDockerBuildOpts{
		BuildArgs: []BuildArg{
			{Name: "version", Value: baseImageVersion},
		},
	}).
		WithLabel("org.opencontainers.image.url", "https://brew.sh").
		WithLabel("org.opencontainers.image.licenses", "BSD-2-Clause").
		WithLabel("org.opencontainers.image.documentation", "https://docs.brew.sh").
		// TODO: you have got to fix this
		WithLabel("org.opencontainers.image.created", time.Now().UTC().Format("2006-01-02 15:04:05-07:00")).
		WithLabel("org.opencontainers.image.source", "https://github.com/"+githubRepo).
		WithLabel("org.opencontainers.image.version", brewVersion).
		WithLabel("org.opencontainers.image.revision", commitSha).
		WithLabel("org.opencontainers.image.vendor", repoOwner)
}

// publishes to both docker.io and ghcr registries
func (m *Brew) PublishAll(ctx context.Context, src *Directory,
	hubUsername string,
	hubToken *Secret,
	ghUsername string,
	ghToken *Secret,
	commitSHA string,
	brewVersion string,
	repo string,
	repoOwner string,
) error {
	if err := m.Publish(ctx, src, "docker.io", hubUsername, hubToken, commitSHA, brewVersion, repo, repoOwner); err != nil {
		return err
	}
	return m.Publish(ctx, src, "ghcr.io", ghUsername, ghToken, commitSHA, brewVersion, repo, repoOwner)
}

// publishes image to specified registry
func (m *Brew) Publish(ctx context.Context, src *Directory,
	registry,
	username string,
	token *Secret,
	commitSHA string,
	brewVersion string,
	repo string,
	repoOwner string,
) error {
	eg := errgroup.Group{}

	eg.Go(func() error {
		for _, version := range versions {
			c := m.BaseContainer(src, version, commitSHA, repo, repoOwner, version, brewVersion)

			addr, err := c.
				WithRegistryAuth(registry, username, token).
				Publish(ctx, registry+"/"+username+"/brew-ubuntu:"+version)
			if err != nil {
				return err
			}
			fmt.Println("published at", addr)

			addr, err = c.
				Publish(ctx, registry+"/"+username+"/brew-ubuntu:latest")
			if err != nil {
				return err
			}

			if version == "22.04" {
				addr, err = c.
					Publish(ctx, registry+"/"+username+"/brew:latest")
				if err != nil {
					return err
				}
			}

			fmt.Println("published at", addr)
		}
		return nil
	})

	return eg.Wait()
}

// runs brew test-bot against latest ubuntu image
func (m *Brew) Test(ctx context.Context,
	src *Directory,
	// +default="24.04"
	version string,
	// +default=""
	commitSHA string,
	// +default=""
	brewVersion string,
) error {
	_, err := m.BaseContainer(src, version, commitSHA, "", "", version, brewVersion).
		WithExec([]string{"brew", "test-bot", "--only-setup"}).Sync(ctx)
	if err != nil {
		return err
	}

	return nil
}

// runs brew test-bot against all versions
func (m *Brew) TestAll(ctx context.Context,
	src *Directory,
	// +default=""
	commitSHA string,
	// +default=""
	brewVersion string,
) error {
	eg := errgroup.Group{}

	for _, version := range versions {
		eg.Go(func() error {
			_, err := m.BaseContainer(src, version, commitSHA, "", "", version, brewVersion).
				WithExec([]string{"brew", "test-bot", "--only-setup"}).Sync(ctx)
			return err
		})
	}

	return eg.Wait()
}
