# Deploying on Heroku

## Manual deployment

This tutorial assumes that you have already managed to clone Consul Democracy on your machine and gotten it to work.

1. First, create a [Heroku](https://www.heroku.com) account if it isn't already done.
2. Install the [Heroku CLI](https://devcenter.heroku.com/articles/heroku-cli) and sign in using:

  ```bash
  heroku login
  ```

3. Go to your Consul Democracy repository and instantiate the process:

  ```bash
  cd consuldemocracy
  heroku create your-app-name
  ```

  You can add the flag `--region eu` if you want to use their European servers instead of the US ones.

  If _your-app-name_ is not already taken, Heroku should now create your app.

4. Create a database using:

  ```bash
  heroku addons:create heroku-postgresql
  ```

  You should now have access to an empty Postgres database whose address was automatically saved as an environment variable named _DATABASE\_URL_. Consul Democracy will automatically connect to it when deployed.

5. Now, generate a secret key and save it to an ENV variable named SECRET\_KEY\_BASE using:

  ```bash
  heroku config:set SECRET_KEY_BASE=$(rails secret)
  ```

  Also add your server address:

  ```bash
  heroku config:set SERVER_NAME=myserver.address.com
  ```

  You need to let the app know where the configuration variables are stored by adding a link to the ENV variables in _config/secrets.yml_

  ```yml
  production:
    secret_key_base: <%= ENV["SECRET_KEY_BASE"] %>
    server_name: <%= ENV["SERVER_NAME"] %>
  ```

  and commit this file in the repo by commenting out the corresponding line in the _.gitignore_.

  ```gitignore
  #/config/secrets.yml
  ```

  **Remember not to commit the file if you have any sensitive information in it!**

6. To ensure Heroku correctly detects and uses the node.js version defined in the project, we need to make the following changes:

  In package.json, add the node.js version:

  ```json
  "engines": {
    "node": "20.18.3"
  }
  ```

  and apply:

  ```bash
  heroku buildpacks:add heroku/nodejs
  ```

7. You can now push your app using:

  ```bash
  git push heroku your-branch:master
  ```

8. It won't work straight away because the database doesn't contain the tables needed. To create them, run:

  ```bash
  heroku run rake db:migrate
  heroku run rake db:seed
  ```

9. Your app should now be ready to use. You can open it with:

  ```bash
  heroku open
  ```

  You also can run the console on Heroku using:

  ```bash
  heroku console --app your-app-name
  ```

10. Heroku doesn't allow saving images or documents in its servers, so it's necessary to setup a permanent storage space.

  See [our S3 guide](using-aws-s3-as-storage.md) for more details about configuring ActiveStorage with S3.

### Configure Twilio Sendgrid

Add the Twilio SendGrid add-on in Heroku. This will create a Twilio SendGrid account for the application with a username and allow you to create a password. This username and password can be stored in the application’s environment variables on Heroku:

```bash
heroku config:set SENDGRID_USERNAME=example-username SENDGRID_PASSWORD=xxxxxxxxx
```

Now add this to `config/secrets.yml`, under the `production:` section:

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

**Important:** Turn on one worker dyno so that emails get sent.
