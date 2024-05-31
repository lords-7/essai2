package main

import (
	"context"
	"time"
)

// var versions = []string{"20.04", "18.04", "16.04"}
var versions = []string{"20.04"}

type Brew struct{}

// BaseContainer returns the container from homebrew's Dockerfile.
func (m *Brew) BaseContainer(src *Directory, version, commitSha, githubRepo, repoOwner, baseImageVersion string) *Container {
	return src.DockerBuild(DirectoryDockerBuildOpts{
		BuildArgs: []BuildArg{
			{Name: "version", Value: baseImageVersion},
		},
	}).
		WithLabel("org.opencontainers.image.url", "https://brew.sh").
		WithLabel("org.opencontainers.image.licenses", "BSD-2-Clause").
		WithLabel("org.opencontainers.image.documentation", "https://docs.brew.sh").
		// TODO: you have got to fix this
		WithLabel("org.opencontainers.image.created", time.Now().UTC().Format(time.RFC3339)).
		WithLabel("org.opencontainers.image.source", "https://github.com/"+githubRepo).
		WithLabel("org.opencontainers.image.version", version).
		WithLabel("org.opencontainers.image.revision", commitSha).
		WithLabel("org.opencontainers.image.vendor", repoOwner)
}

// foo
func (m *Brew) Test(ctx context.Context, src *Directory) error {
	src = src.WithoutDirectory("dagger").WithoutFile("dagger.json")

	for _, version := range versions {
		_, err := m.BaseContainer(src, version, "foo", "franela/brew", "franela", version).
			WithExec([]string{"brew", "test-bot", "--only-setup"}).Sync(ctx)
		if err != nil {
			return err
		}
	}

	return nil
}
