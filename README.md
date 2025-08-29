Build:

With last version of indi

```bash
docker build -t astrootter/indiserver:latest .
```

With a specific version of INDI

```bash
docker build --build-arg INDI_VERSION=v2.1.5 -t astrootter/indiserver:v2.1.5 .
```


Run
```bash
docker run -d -p 7624:7624 astrootter/indiserver
```

