# openproject-railway

Wrapper image that lets [OpenProject](https://github.com/opf/openproject) (GPL-3.0) run as a Railway template.

`ghcr.io/bon5co/openproject-railway` wraps the official `openproject/openproject` 17.9.8 slim image. Upstream's compose runs four
containers from that image (web, worker, cron, one-shot seeder) that share an assets volume; a Railway volume attaches to one
service, so this image runs the seeder, the web server and the background worker in one container on one volume. It creates the
admin login from `ADMIN_PASSWORD` (and `ADMIN_EMAIL`), and turns public self-registration off, which upstream leaves open.

The Railway template that uses it is published from the `bon5co` workspace; this repository holds only the image.
