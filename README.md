## WORK IN PROGRESS
## DO NOT BUILD AND RUN YET 



WARNING: tags in indilib github repository are prefixed with letter "v"

#### Build from Docker hub 
Same commands but : 
```bash
docker pull astrootter/indiserver:latest
```

#### Run
```bash
docker run -d -p 7624:7624 -p 8624:8624 --name indiserver -it astrootter/indiserver:latest
```
# -p 8624:8624
Access to indiwebmanager on `http://<ip>:8624`


#### Debug Build Dockerfile

With last version of indi

Build with Dockerfile:
```bash
docker build --no-cache -t astrootter/indiserver:latest .
```

With a specific version of INDI
```bash
docker build --no-cache --build-arg INDI_VERSION=v2.1.5 -t astrootter/indiserver:v2.1.5 .
```
With driver(s)
```bash
docker build \
  --no-cache \
  --build-arg INDI_VERSION=2.1.5 \
  --build-arg "INDI_DRIVERS=indi-eqmod indi-asi" \
  -t astrootter/indiserver:2.1.5 .
```
