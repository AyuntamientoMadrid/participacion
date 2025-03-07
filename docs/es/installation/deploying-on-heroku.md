# Instalación en Heroku

## Instalación manual

Este tutorial asume que ya has conseguido clonar Consul Democracy en tu máquina y conseguir que funcione.

1. En primer lugar, necesitas crear una cuenta en [Heroku](https://www.heroku.com) si no lo has hecho ya.
2. Instala [Heroku CLI](https://devcenter.heroku.com/articles/heroku-cli) e inicia sesión con:

  ```bash
  heroku login
  ```

3. Accede a tu repositorio de Consul Democracy y crea una instancia:

  ```bash
  cd consuldemocracy
  heroku create your-app-name
  ```

  Puedes añadir `--region eu` si quieres utilizar servidores europeos en lugar de los estadounidenses.

  Si _your-app-name_ no existe aún, Heroku creará tu aplicación.

4. Crea la base de datos con:

  ```bash
  heroku addons:create heroku-postgresql
  ```

  Ahora deberías tener acceso a una base de datos Postgres vacía cuya dirección se guardó automáticamente como una variable de entorno llamada _DATABASE\_URL_. Consul Democracy se conectará automáticamente a ella durante la instalación.

5. Ahora, genera una clave secreta y guárdala en la variable de entorno SECRET\_KEY\_BASE de la siguiente manera:

  ```bash
  heroku config:set SECRET_KEY_BASE=$(rails secret)
  ```

  Añade también la dirección de tu servidor:

  ```bash
  heroku config:set SERVER_NAME=myserver.address.com
  ```

  Es necesario que la aplicación sepa dónde se almacenan las variables de configuración añadiendo un enlace a las variables de entorno en _config/secrets.yml_

  ```yml
  production:
    secret_key_base: <%= ENV["SECRET_KEY_BASE"] %>
    server_name: <%= ENV["SERVER_NAME"] %>
  ```

  y añade este archivo en el repositorio comentando la línea correspondiente en el _.gitignore_.

  ```gitignore
  #/config/secrets.yml
  ```

  **¡Recuerda no añadir el archivo si tienes información sensible en él!**

6. Para que Heroku detecte y utilice correctamente la versión de node.js definida en el proyecto deberemos añadir los siguientes cambios:

  En el _package.json_  añadir la versión de node.js:

  ```json
  "engines": {
    "node": "20.18.3"
  }
  ```

  y aplicar:

  ```bash
  heroku buildpacks:add heroku/nodejs
  ```

7. Ahora ya puedes subir tu aplicación utilizando:

  ```bash
  git push heroku your-branch:master
  ```

8. No funcionará de inmediato porque la base de datos no contiene las tablas necesarias. Para crearlas, ejecuta:

  ```bash
  heroku run rake db:migrate
  heroku run rake db:seed
  ```

9. Ahora tu aplicación debería estar ya operativa. Puedes abrirla con:

  ```bash
  heroku open
  ```

  También puedes arrancar la consola en heroku utilizando

  ```bash
  heroku console --app your-app-name
  ```

10. Heroku no permite guardar imágenes o documentos en sus servidores, por lo que es necesario configurar un nuevo espacio de almacenamiento.

  Consulta [nuestra guía de S3](using-aws-s3-as-storage.md) para más detalles sobre la configuración de ActiveStorage con S3.

### Configurar Twilio SendGrid

Añade el complemento (_add-on_) de Twilio SendGrid en Heroku. Esto creará una cuenta en Twilio SendGrid para la aplicación con un nombre de usuario y permitirá crear una contraseña. Este usuario y contraseña lo podemos guardar en las variables de entorno de la aplicación en Heroku:

```bash
heroku config:set SENDGRID_USERNAME=example-username SENDGRID_PASSWORD=xxxxxxxxx
```

Ahora añade el siguiente código a `config/secrets.yml`, en la sección `production:`:

```yaml
  mailer_delivery_method: :smtp
  smtp_settings:
    :address: "smtp.sendgrid.net"
    :port: 587
    :domain: "heroku.com"
    :user_name: ENV["SENDGRID_USERNAME"]
    :password: ENV["SENDGRID_PASSWORD"]
    :authentication: "plain"
    :enable_starttls_auto: true
```

**Importante:** Activa un "_worker dyno_" para que se envíen los correos electrónicos.
