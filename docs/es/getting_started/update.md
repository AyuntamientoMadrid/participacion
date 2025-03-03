# Mantén tu fork actualizado

## Pasos previos

### Ejecuta los tests

Antes de actualizar a una versión más reciente de Consul Democracy, asegúrate de que has [configurado tu fork](configuration.md) para que ejecute los tests, y que todos los tests pasan. Si te saltas este paso, será mucho más difícil actualizar ya que no habrá una manera fiable de comprobar si alguna funcionalidad se ha roto tras la actualización.

Dedica a este paso tanto tiempo como necesites; por cada hora que pases asegurándote de que tus tests funcionan correctamente te ahorrarás numerosas horas de arreglar fallos que llegaron a producción.

### Configura tus servidores remotos de git

Si creaste tu fork siguiendo las instrucciones de la sección [Creat tu fork](create.md) y lo clonaste en tu máquina, ejecuta:

```bash
git remote -v
```

Deberías ver algo como:

> origin  git@github.com:your_user_name/consuldemocracy.git (fetch)\
> origin  git@github.com:your_user_name/consuldemocracy.git (push)

Ahora añade el repositorio git de Consul Democracy como servidor remoto con:

```bash
git remote add upstream git@github.com:consuldemocracy/consuldemocracy.git
```

Comprueba que se ha configurado correctamente ejecutando nuevamente:

```bash
git remote -v
```

Esta vez deberías ver algo como:

> origin  git@github.com:your_user_name/consuldemocracy.git (fetch)\
> origin  git@github.com:your_user_name/consuldemocracy.git (push)\
> upstream  git@github.com:consuldemocracy/consuldemocracy.git (fetch)\
> upstream  git@github.com:consuldemocracy/consuldemocracy.git (push)

## Obteniendo cambios de Consul Democracy

Cuando actualices Consul Democracy, **es muy importante que actualices las versiones de una en una**. Algunas versiones requieren ejecutar tareas que modifican contenido de la base de datos para que este contenido sea compatible con futuras versiones. Actualizar dos versiones de golpe podría resultar en una pérdida irreversible de datos.

Cuando decimos "de una en una", no tenemos en cuenta las versiones de mantenimiento (en inglés, "patch"). Por ejemplo, si estás usando la versión 1.2.0 y quieres actualizar a la versión 2.2.2, actualiza primero a la versión 1.3.1, luego  la 1.4.1, luego a la 1.5.0, luego a la 2.0.1, luego a la 2.1.1 y finalmente a la 2.2.2. Esto es, actualiza siempre a la última versión "patch" de una versión mayor/menor.

Al actualizar a una versión, lee las [notas de versión](https://github.com/consuldemocracy/consuldemocracy/releases) de dicha versión **antes** de actualizar.

Para actualizar, empieza creando una rama `release` a partir de tu rama `master`:

```bash
git checkout master
git pull
git checkout -b release
git fetch upstream tag <etiqueta_de_la_versión_a_la_que_estás_actualizando>
```

Ahora estás listo para fusionar los cambios de la nueva versión.

## Fusionando cambios

Ejecuta:

```bash
git merge  <version_tag_you_are_upgrading_to>
```

Tras ejecutar esta orden, hay dos posibles escenarios:

A. Se abre una ventana del editor que tengas configurado en git, mostrando el mensaje de commit `Merge '<version_tag_you_are_upgrading_to>' into release`. Esto significa que git fue capaz de mezclar los cambios de Consul Democracy sobre tu código sin encontrar problemas o conflictos. Termina el commit.

B. Recibes mensajes de error de git junto con un `Automatic merge failed; fix conflicts and then commit the result`. Esto significa que se han encontrado conflictos entre los cambios en tu código y los cambios en la nueva versión de Consul Democracy. Esta es una de las principales razones por las que recomendamos [usar los directorios y archivos "custom" para tus cambios](../customization/introduction.md); cuanto más uses los directorios y archivos "custom", menos conflictos tendrás. Resuelve manualmente los conflictos para terminar el merge y haz un commit, documentando cómo resolviste los conflictos (por ejemplo, en el mensaje de commit).

## Comprueba que todo funciona

Ahora, te recomendamos que subas los cambios en tu rama `release` a GitHub (o GitLab, si es lo que usas normalmente) y abras una "Pull Request" para comprobar si todos los tests funcionan correctamente.

Es posible que al ejecutar los tests veas que algunos fallen porque los cambios que has hecho en el código no sean compatibles con la nueva versión de Consul Democracy. Es **esencial** que arregles estos fallos antes de seguir adelante.

Por último, vendría bien que comprobases manualmente tu código. Por ejemplo, si has [personalizado componentes](../customization/components.md) o [vistas](../customization/views.md), comprueba si los archivos ERB originales han cambiado y, en caso afirmativo, si deberías actualizar tus archivos personalizados para incluir estos cambios.

## Pasos finales

Una vez comprobado que todo funciona, puedes los cambios de la "Pull Request" en tu rama `master` utilizando la interfaz de GitHub/GitLab o terminar el proceso manualmente:

```bash
git checkout master
git merge release
git branch -d release
git push
```

Por último, lee las notas de versión una vez más para asegurarte de que todo está bajo control, sube estos cambios a producción, ejecuta `bin/rake consul:execute_release_tasks RAILS_ENV=production` en el servidor de producción, y comprueba que todo funciona como debería.

¡Enhorabuena! Has actualizado a una versión más reciente de Consul Democracy. Tu versión de Consul Democracy es ahora más resistente a posibles problemas de seguridad y tiene un menor peligro de quedar abandonada por ser imposible de mantener. No solo eso, sino que esta experiencia hará que te sea más fácil actualizar a una nueva versión en el futuro.

¡Nos encantaría escuchar cómo te ha ido! Para esto, puedes usar las [conversaciones sobre nuevas versiones](https://github.com/consuldemocracy/consuldemocracy/discussions/categories/releases) (ten en cuenta que no hay conversaciones para versiones anteriores a la 2.2.0; is has actualizado a una versión anterior, abre una nueva conversación). Así, entre todos conseguiremos que tanto tú como las demás personas que usan Consul Democracy puedan actualizar más fácilmente la próxima vez.
