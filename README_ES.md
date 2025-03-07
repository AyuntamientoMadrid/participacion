<!--
  Title: CONSUL DEMOCRACY
  Description: Aplicación de Participación Ciudadana y Gobierno Abierto
  Keywords: democracia, participación ciudadana, participación electrónica, debates, propuestas, votaciones, consultas, legislación colaborativa, presupuestos participativos
-->

![Logotipo de CONSUL DEMOCRACY](https://raw.githubusercontent.com/consuldemocracy/consuldemocracy/master/public/consul_logo.png)

# CONSUL DEMOCRACY

Aplicación de Participación Ciudadana y Gobierno Abierto

[![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](http://www.gnu.org/licenses/agpl-3.0)
[![Accessibility conformance](https://img.shields.io/badge/accessibility-WAI:AA-green.svg)](https://www.w3.org/WAI/eval/Overview)

![Estado de los tests](https://github.com/consuldemocracy/consuldemocracy/workflows/tests/badge.svg)
[![Code Climate](https://codeclimate.com/github/consuldemocracy/consuldemocracy/badges/gpa.svg)](https://codeclimate.com/github/consuldemocracy/consuldemocracy)
[![Coverage Status](https://coveralls.io/repos/github/consuldemocracy/consuldemocracy/badge.svg?branch=master)](https://coveralls.io/github/consuldemocracy/consuldemocracy?branch=master)
[![Crowdin](https://d322cqt584bo4o.cloudfront.net/consul/localized.svg)](https://translate.consuldemocracy.org/)

[![Help wanted](https://img.shields.io/badge/help-wanted-brightgreen.svg?style=flat-square)](https://github.com/consuldemocracy/consuldemocracy/issues?q=is%3Aopen+label%3A"help+wanted")

Este es el repositorio de código abierto de la Aplicación de Participación Ciudadana CONSUL DEMOCRACY, creada originariamente por el Ayuntamiento de Madrid.

## Documentación

Por favor visita la documentación que está siendo completada en [https://docs.consuldemocracy.org](https://docs.consuldemocracy.org) para conocer más sobre este proyecto, cómo comenzar tu propio fork, instalarlo, personalizarlo y usarlo como administrador/mantenedor.

## Web CONSUL DEMOCRACY Project

Puedes acceder a la página principal del proyecto en [http://consuldemocracy.org](http://consuldemocracy.org) donde puedes encontrar documentación sobre el uso de la plataforma, videos y enlaces al espacio de la comunidad.

## Configuración para desarrollo y tests

**NOTA**: para unas instrucciones más detalladas, consulta la [documentación de instalación local](docs/es/installation/local_installation.md).

Prerrequisitos: tener instalado git, Ruby 3.2.7, CMake, pkg-config, Node.js 20.18.3, ImageMagick y PostgreSQL (9.5 o superior).

**Nota**: Es posible que ejecutar `bin/setup`, como se indica a continuación, falle si has configurado un nombre de usuario y contraseña para PostgreSQL. Si es así, edita las líneas que contienen `username:` y `password:` (añadiendo tus credenciales) en el fichero `config/database.yml` y ejecuta `bin/setup` de nuevo.

```bash
git clone https://github.com/consuldemocracy/consuldemocracy.git
cd consuldemocracy
bin/setup
bin/rake db:dev_seed
```

Para ejecutar la aplicación en local:

```bash
bin/rails s
```

Para ejecutar los tests:

```bash
bin/rspec
```

Nota: ejecutar todos los tests en tu máquina puede tardar más de una hora, por lo que recomendamos encarecidamente que configures un sistema de Integración Continua para ejecutarlos utilizando varios trabajos en paralelo cada vez que abras o modifiques una PR (si usas GitHub Actions o GitLab CI, esto ya está configurado en `.github/workflows/tests.yml` y `.gitlab-ci.yml`) y cuando trabajes en tu máquina ejecutes solamente los tests relacionados con tu desarrollo actual. Al configurar la aplicación por primera vez, recomendamos que ejecutes al menos un test en `spec/models/` y un test en `spec/system/` para comprobar que tu máquina está configurada para ejecutar los tests correctamente.

Puedes usar el usuario administrador por defecto del fichero seeds:

 **user:** admin@consul.dev
 **pass:** 12345678

Pero para ciertas acciones, como apoyar, necesitarás un usuario verificado, el fichero seeds proporciona uno:

 **user:** verified@consul.dev
 **pass:** 12345678

## Estado del proyecto

El desarrollo de esta aplicación comenzó el [15 de Julio de 2015](https://github.com/consuldemocracy/consuldemocracy/commit/8db36308379accd44b5de4f680a54c41a0cc6fc6) y el código fue puesto en producción el día 7 de Septiembre de 2015 en [decide.madrid.es](https://decide.madrid.es). Desde entonces se le añaden mejoras y funcionalidades constantemente. Las funcionalidades actuales se pueden consultar en la [la página del projecto](http://consuldemocracy.org/es) y las futuras funcionalidades en el [Roadmap](https://github.com/consuldemocracy/consuldemocracy/projects/6) y [el listado de issues](https://github.com/consuldemocracy/consuldemocracy/issues).

## Licencia

El código de este proyecto está publicado bajo la licencia AFFERO GPL v3 (ver [LICENSE-AGPLv3.txt](LICENSE-AGPLv3.txt))

## Contribuciones

Ver fichero [CONTRIBUTING_ES.md](CONTRIBUTING_ES.md)

## Desarrollo en local con Docker

Puedes leer la guía en [https://consul_docs.gitbooks.io/docs/content/es/getting_started/docker.html](https://consul_docs.gitbooks.io/docs/content/es/getting_started/docker.html)
