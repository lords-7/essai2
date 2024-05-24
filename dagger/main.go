package main

import "time"

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
