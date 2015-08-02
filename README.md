# Aplicación de Participación Ciudadana del Ayuntamiento de Madrid

Este es el repositorio de código abierto de la Aplicación de Participación Ciudadana del Ayuntamiento de Madrid.

## Estado del proyecto

El desarrollo de esta aplicación comenzó el [15 de Julio de 2015](https://github.com/AyuntamientoMadrid/participacion/commit/8db36308379accd44b5de4f680a54c41a0cc6fc6)

Este proyecto está en las primeras fases de su desarrollo. Las funcionalidades actualmente presentes en el código, así como sus nombres, deben considerarse como provisionales.

## Tecnología

El backend de esta aplicación se desarrolla con el lenguaje de programación [Ruby](https://www.ruby-lang.org/) sobre el *framework* [Ruby on Rails](http://rubyonrails.org/).
Las herramientas utilizadas para el frontend no están cerradas aún. Los estilos de la página usan [SCSS](http://sass-lang.com/) sobre [Foundation](http://foundation.zurb.com/)

## Configuración para desarrollo y tests

Prerequisitos: tener instalado git, Ruby 2.2.2, la gema `bundler`, y una librería moderna de PostgreSQL.

```
cd participacion
bundle install
cp config/database.yml.example config/database.yml
cp config/secrets.yml.example config/secrets.yml
bundle exec bin/rake db:create db:schema_load
RAILS_ENV=test bundle exec rake db:create db:schema_load
```

Para ejecutar la aplicación en local:
```
bundle exec bin/rails s
```

Para ejecutar los tests:
```
bundle exec bin/rspec
```

## Vagrant

Prerequisitos: 

* Instalar [Vagrant](http://www.vagrantup.com/downloads.html)
* Instalar [ChefDK](https://downloads.chef.io/chef-dk/)
* Plugin de Berkshelf de vagrant ```vagrant plugin install vagrant-berkshelf```

Uso:

```vagrant up``` y abrir el navegador en http://127.0.0.1:8888

```vagrant destroy``` para destruir la maquina virtual



## Licencia

El código de este proyecto está publicado bajo la licencia MIT (ver MIT-license.md)

## Contribuciones

Ver fichero CONTRIBUTING.md
