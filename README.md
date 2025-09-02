# Docker INDI Server

A Docker container for running INDI (Instrument Neutral Distributed Interface) server with libraries, drivers and Web-manager for astronomical equipment control.

## Features

- **INDI Core Library** with automatic version detection
- **Customizable third-party drivers** support
- **Multi-platform support** (x86_64, ARM64)
- **Raspberry Pi optimized** version with libcamera support (IN PROGRESS)
- **Web management interface** via INDI Web Manager
- **Lightweight runtime** with only necessary components

## Supported Platforms

- **Standard platforms**: x86_64, ARM64 (using Debian base)
- **Raspberry Pi**: Optimized version with native libcamera support

## Quick Start

## Standart use

```bash
# Pull docker image from docker Hub
docker pull astrootter/indiserver-full
```

### Debug Build (Debian-based)

```bash
# Clone the repository
git clone https://github.com/Astro-Otter-Space/docker-indiserver.git
cd docker-indiserver

# Build with default INDI version (latest stable)
docker --no-cache -t astrootter/indiserver-full:latest .

# Build with specific INDI version and drivers (OPTIONNAL REMOVED)
#docker build \
#  --build-arg INDI_VERSION=v2.0.8 \
#  --build-arg INDI_DRIVERS="indi-asi indi-qhy indi-canon" \
#  -t indi-server .
```

### Raspberry Pi Build

WORK IN PROGRESS 
```bash
# Build for Raspberry Pi with libcamera support
docker build -f Dockerfile.raspberrypi \
  --build-arg INDI_DRIVERS="indi-libcamera indi-asi" \
  -t indi-server-rpi .
```

### Running the Container

```bash
# Run INDI Web Manager (option -d is for running in background)
docker run -d -p 7624:7624 -p 8624:8624 --name indiserver-full -it astrootter/indiserver-full:latest

# Run with USB device access for cameras/mounts
docker run -d -p 7624:7624 -p 8624:8624 --privileged -v /dev:/dev astrootter/indiserver-full:latest
```

## Build Arguments (OBSOLETE)

| Argument | Description | Default | Example |
|----------|-------------|---------|---------|
| `INDI_VERSION` | INDI version to build | Latest stable | `v2.0.8` |
| `INDI_DRIVERS` | Space-separated list of drivers | None | `"indi-asi indi-qhy indi-canon"` |

## Available Drivers

The following third-party drivers are available (must exist in [indi-3rdparty repository](https://github.com/indilib/indi-3rdparty)):

## Accessing the Web Interface

After starting the container, open your browser and navigate to:

```
http://localhost:8624
```

From the web interface, you can:
- Start/stop INDI drivers
- Configure driver settings
- Monitor connected devices
- View logs and status

## Docker Compose

Create a `docker-compose.yml` file:

```yaml
version: '3.8'
services:
  indi-server:
    build:
      context: .
    ports:
      - "8624:8624"
    privileged: true
    volumes:
      - /dev:/dev
    restart: unless-stopped
```

Run with:
```bash
docker-compose up -d
```

## Troubleshooting

### Driver Not Found
If you get a "Driver directory not found" warning:
1. Check the [indi-3rdparty repository](https://github.com/indilib/indi-3rdparty) for the correct driver name
2. Ensure the driver exists for your INDI version
3. Check the build logs for available drivers list

### USB Device Not Detected
- Ensure the container runs with `--privileged` flag
- Mount `/dev` volume: `-v /dev:/dev`
- Check device permissions on the host

### Permission Issues
- The container runs as user `astro` with sudo privileges
- USB devices may need udev rules on the host system

### Version Compatibility
- Some drivers may not be available for all INDI versions
- Check driver compatibility in the [INDI documentation](https://www.indilib.org/)

## Development

### Building Custom Drivers

To add custom drivers:
1. Fork this repository
2. Modify the `INDI_DRIVERS` build argument
3. Ensure your driver exists in the indi-3rdparty repository
l
### Architecture Support

The Dockerfiles support:
- **Dockerfile**: Multi-arch (x86_64, ARM64) using Debian
- **Dockerfile.raspberrypi**: ARM64 optimized for Raspberry Pi OS

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with different driver combinations
5. Submit a pull request

## License

This project is open source. Please check individual driver licenses in the INDI project.

## Links

- [INDI Library](https://www.indilib.org/)
- [INDI GitHub](https://github.com/indilib/indi)
- [INDI 3rd Party Drivers](https://github.com/indilib/indi-3rdparty)
- [INDI Web Manager](https://github.com/knro/indiwebmanager)

## Support

For issues specific to this Docker setup:
- [Create an issue](https://github.com/Astro-Otter-Space/docker-indiserver/issues)

For INDI-related questions:
- [INDI Forum](https://indilib.org/forum/)
- [INDI Documentation](https://www.indilib.org/develop/developer-manual.html)