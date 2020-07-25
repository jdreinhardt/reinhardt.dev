+++
title = "Multi-architecture Containers with BuildKit"
date = "2020-07-24T13:38:19-06:00"
author = "derek"
draft = false
cover = ""
tags = ["docker", "multi-arch", "buildx"]
keywords = ["docker", "buildx"]
description = "Easily build Docker containers for system architectures other than that of the system executing the build."
showFullContent = false
+++

Docker is a wonderful tool for packaging applications for easy deployment into a variety of environments. I personally have been experimenting with a Docker Swarm at home on a number of Raspberry Pis. It's been a great learning experience, and I am constantly amazed by what can be done with a $35 computer. The issue I encountered very quickly was that I could usually find an image of an application on Docker Hub, but it was often only built for amd64 architectures which will not run on the Raspberry Pi's arm/v7. Luckily, Docker has a built in utility (starting with 19.03) called Docker BuildKit (buildx) which allows for building images for alternative architectures from the machine building the image.

## Setup

First install Docker on your system. The Docker website has a number of gudies and instructions to accomplish this. Now, before you can start using Buildx you will need to enable experimental features in the config. On Windows and Mac there is a checkbox in the application to enable Experimental. On Linux, open `~/.docker/config.json` in the text editor of your choosing. If it doesn't exist you will need to make it. Place the following in the file.

```json
{
    "experimental": "enabled"
}
```

After that, restart Docker. You should now get a usage output in your terminal when typing `docker buildx`. Running `docker buildx ls` will show you all available builders and the architectures they are able to build for. For now you should see a default builder only capable of building for your systems architecture.

## Configuration

To be able to build for multiple architectures we need to create a builder that includes the needed QEMU binfmt binaries. We can create a new builder by running 

```bash
docker buildx create --name xbuilder
```

The name is for convience only, so you can use whatever name you prefer. This will create the builder, but not set it for use. To do that you need to run

```bash
docker buildx use xbuilder
```

Now, when you call a buildx command the specified one will be used. As of right now it does not have the ability to build for the other architectures. To do that we need to run a docker image that contains the binfmt binaries in privileged mode to allow the builder access to them.

```bash
docker run --rm --privileged linuxkit/binfmt:v0.8 #latest as of writing
```

Now with all the other parts in place we can start our builder. This will make it ready for use

```bash
docker buildx inspect --bootstrap
```

You can verify that everything started correctly by running `docker buildx ls` again. You should now see `xbuilder` listed as one of the builders and a long list of available platforms.

## Usage

Building images with BuildKit is not much different from building a regular image with Docker. The biggest difference being that you need to specify the architectures you want to build for your `Dockerfile`. A simple build command would look like 

```bash
docker buildx build --platform=linux/amd64,linux/arm/v7,linux/arm64 --push -t jdreinhardt/test:latest .
```

In this example I am building for `amd64` which is most computers, `arm/v7` which is most SBC including the Raspberry Pi, and `arm64` which is found on newer SBCs including the Pi 4. `--push` specifies that the resulting images are to be pushed to Docker Hub using the tags, `-t`, specified. If you wish to build locally only you can use `--load` instead which will copy the resulting image out of the builder and to your local system. This does have the limitation that only one architecture can be specified using platform.

There is plenty more to learn, but this should get you started on building Dockerfiles for multiple architectures without the need for multiple devices.