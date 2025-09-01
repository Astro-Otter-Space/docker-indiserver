## WORK IN PROGRESS DO NOT BUILD AND RUN YET 

## Get image from Docker hub

WARNING: tags in indilib github repository are prefixed with letter "v"
```bash
docker pull astrootter/indiserver:latest
```
If you want a specific INDI version
```bash
docker pull astrootter/indiserver:latest
```

If `INDI_VERSION` is not setted, the last release will be compiled

## Run image
```bash
docker run -d -p 7624:7624 -p 8624:8624 --name indiserver -it astrootter/indiserver:latest
```
Access to indiwebmanager on `http://<ip>:8624`

## Debug Build Dockerfile

Build with Dockerfile:
```bash
docker build -f Dockerfile --no-cache -t astrootter/indiserver:latest .
```
Specific to raspbery PI :
```bash
docker build -f Dockerfile.raspberrypi --no-cache -t astrootter/indiserver:latest .
```

Like for `docker run` you can add arguments 
