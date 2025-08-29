## WORK IN PROGRESS
## DO NOT BUILD AND RUN YET 

#### Build:

With last version of indi

```bash
docker build -t astrootter/indiserver:latest .
```

With a specific version of INDI

```bash
docker build --build-arg INDI_VERSION=2.1.5 -t astrootter/indiserver:v2.1.5 .
```
With driver(s)
```bash
docker build \
  --build-arg INDI_VERSION=2.1.5 \
  --build-arg "INDI_DRIVERS=indi-eqmod indi-asi" \
  -t astrootter/indiserver:2.1.5 .
```


#### Run
```bash
docker run -d -p 8624:8624 -p 7624:7624 astrootter/indiserver:latest
```
Access to indiwebmanager on `http://<ip>:8624`
