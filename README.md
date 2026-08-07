# irrigation-control

Steuerung einer Gartenbewaesserungsanlage. Die technische Auswahl fuer Frontend,
Backend und Raspberry-Pi-Image erfolgt zu einem spaeteren Zeitpunkt.

## Projektstruktur

```text
apps/
	frontend/             Web- oder mobile Bedienoberflaeche
		src/
	backend/              API, Bewaesserungslogik und Persistenz
		src/
pi-image/               Build- und Konfigurationsdateien fuer das Raspberry-Pi-Image
	overlays/              Dateisystem-Overlays fuer das Image
shared/
	contracts/             Gemeinsame Schnittstellen und Datenmodelle
infrastructure/         Deployment, Netzwerk und Betriebs-Konfiguration
docs/                   Architektur, Hardware und Betriebsdokumentation
```
