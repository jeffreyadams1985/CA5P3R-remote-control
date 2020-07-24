# Remote Admin

## Описание системы

Система задумана как прототип удалённого управления устройствами с использованием RTP для трансляции видео с экрана устройства, а также WebRTC DataChannel для отправки устройству управляющих команд с минимальной задержкой.

В состав системы входят:

- Janus. Медиасервер
- nginx. Веб-сервер общего назначения
- certbot. Агент дял управления SSL-сертификатами, выпускаемыми LetsEncrypt
- Источник RTP (RTP source). Сервис, имитирующий удалённое устройство. При запуске создаёт защищённые PIN-кодом точку вещания видео и текстовую комнату (DataChannel), реагирует на присоединившихся пользователей, исполняет их команды
- Админка RTP (RTP Web Admin). Веб-страница для удалённого управления устройством. Доступна по адресу: `https://your.domain.ru/rtp-web-admin/`
- Демки Janus. Стандартные демки, можно использовать для проверки работы Janus. Доступны по адресу: `https://your.domain.ru/janus-gateway-test/`

## Инструкция по развёртыванию

Требуется чистый сервер:

- Архитектура `x84_64` / `amd64`
- ОС Ubuntu, варианты:
	- Ubuntu Bionic `18.04 LTS` 
	- Ubuntu Xenial `16.04 LTS` (полностью протестировано на DigitalOcean с версией `16.04.6 LTS`)
- Командная оболочка `bash`

Полностью протестирована и подтверждена работоспособность на хостинге DigitalOcean со следующими версиями Ubuntu:

- Ubuntu Bionic 18.04.3 LTS x64
- Ubuntu Xenial 16.04.6 LTS x64

### Подготовка системы

#### Установка необходимых пакетов

`sudo apt-get update`

`sudo apt-get install -y git`


#### Установка docker
Взято из https://docs.docker.com/engine/install/ubuntu/

```
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common
```

`curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -`

```
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
```

`sudo apt-get update`

`sudo apt-get install -y docker-ce docker-ce-cli containerd.io`


#### Установка docker-compose
Взято из https://docs.docker.com/compose/install/

`sudo curl -L "https://github.com/docker/compose/releases/download/1.26.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose`

`sudo chmod +x /usr/local/bin/docker-compose`

Опционально, можно установить autocompletion для docker-compose (взято отсюда https://docs.docker.com/compose/completion/):

`sudo curl -L https://raw.githubusercontent.com/docker/compose/1.26.0/contrib/completion/bash/docker-compose -o /etc/bash_completion.d/docker-compose`

и сразу включить его в текущей сессии командной строки:

`. /etc/bash_completion.d/docker-compose`

### Загрузка и запуск

#### Получение исходников

Систему необходимо загрузить на сервер посредством `git` из репозитория https://gitlab.com/headwind/remote-control.

Прежде всего, обратитесь к владельцу репозитория для получения доступа на скачивание системы.

Предварительно создайте SSH-ключ для доступа к репозиторию:

`ssh-keygen -t rsa -b 4096 -C "your@email.ru"`

Вместо `your@email.ru` укажите свою почту, на все остальные запросы команды достаточно просто нажимать `Enter`

После успешной генерации ключа, выведите его на экран, скопируйте и отправьте владельцу репозитория, чтобы он добавил ваш ключ для доступа к скачиванию системы:

`cat ~/.ssh/id_rsa.pub`

После того, как вам будет предоставлен доступ, можно склонировать систему:

`git pull git@gitlab.com:headwind/remote-control.git`

Если при клонировании спросит про сертификат, необходимо ввести `yes`

#### Запуск системы

Хоть система и построена на основе `docker-compose` и управляется им же, как минимум первый раз систему нужно запускать с помощью скрипта `start.sh`. В состав системы входит `certbot` для автоматического получения и обновления бесплатных SSL-сертификатов от LetsEncrypt, и для первого запуска нужно предоставить необходимые данные для формирования первого сертификата для вашего хоста.

Необходимые данные:
- *доменное имя*, любого уровня. Например: `example.org`, `super.hidden.host.name.headwind.ru`. К моменту первого запуска в панели управления DNS вашего домена должна быть создана и работать A-запись об этом домене, указывающая на IP-адрес вашего сервера. Проверить работоспособность A-записи о доменном имени можно простой командой `ping my.domain.ru` - вы должны увидеть успешные ответы от сервера с вашим IP-адресом.
- *электронная почта для регистрации сертификата*. Укажите существующий и используемый вами как владельцем или администратором доменного имени ящик. На него приходят различные уведомления о продлении, отзыве и прочие действительно важные сообщения.
- *нужно ли предоставлять вашу электронную почту организации EFF*. На ваш выбор, я обычно не предоставляю.
- *является ли ваше окружение staging-окружением или production*. В случае staging `certbot` сформирует тестовый сертификат, на который браузеры будут ругаться. Обычно, конечно, используется `production`, но `staging` нужен для тестирования самого процесса получения сертификатов (чтобы не исчерпывать лимит кол-ва формирований сертификатов на хост).
- пересоздавать ли принудительно сертификат каждый раз при запуске скрипта `start.sh`. Не рекомендуется, чтобы не исчерпать лимиты формирования сертификатов. `certbot` в составе системы сам при запуске проверяет возможность перевыпуска сертификата и делает это в соответствии с рекомендациями LetsEncrypt.

Данные можно предоставить либо в интерактивном режиме "вопрос-ответ" (всё нужное спросит скрипт `start.sh`), либо с помощью переменных окружения:
- `DOMAIN` - строка с доменом, без префиксных и суффиксных точек
- `EMAIL` - строка с электронной почтой
- `SHARE_EMAIL` - 1 или 0 ("да" или "нет")
- `STAGING` - 1 или 0 ("да" или "нет")
- `FORCE_RECREATE_CERT` - 1 или 0 ("да" или "нет")

Пример полностью автоматического запуска системы (значения параметров, кроме домена и электропочты, являются рекмендованными):

`DOMAIN=remoteadmin.headwind.ru EMAIL=admin@headwind.ru SHARE_EMAIL=0 STAGING=0 FORCE_RECREATE_CERT=0 ./start.sh`

Заданные с помощью переменных окружения или введённые вами интерактивно значения переменных при успешном запуске системы сохранятся в файле `.env.start` и будут использоваться в следующий раз при запуске скрипта `start.sh`.


### Инструкция по эксплуатации

Перед выполнением любых команд, необходимо перейти в папку с системой:

`cd ~/remote-control`

Как упоминалось ранее, система построена на использовании `docker-compose`, поэтому для запуска, перезапуска, остановки системы (и любых других действий) используются её команды.

__Рекомендуемый способ запуска системы, особенно в первый раз__:

`./start.sh`

Также можно запустить в режиме foreground (в консоли, оствновить систему можно будет комбинацией клавиш `Ctrl+C`):

`docker-compose up`

Для реального использований данный режим __НЕ рекомендуется__.

Также, можно запустить в фоне:

`docker-compose up --detach`

Просмотр запущенных сервисов и их состояния:

`docker-compose ps`

Перезапуск:

`docker-compose restart`

Останов:

`docker-compose stop`

Останов с удалением контейнеров, сетей, образов

`docker-compose down`

#### Удалённое управление

При запуске системы контейнер с источником RTP не запускается, и его необходимо запустить вручную:

`docker-compose run rtp-source python main.py --run`

Спустя несколько секунд, после того, как сервис установит соединение с Janus и инициализирует всё нужное для своей работы, вы увидите реквизиты для удалённого доступа, например:

```
============= CONNECT CREDENTIALS ===================
===
=== SESSION ID: 9a24897a-fae3-4167-813b-e8c538551436
=== PIN: 4212
===
=====================================================
```

Это идентификатор сессии удалённого управления и PIN-код для доступа к ней.

Откройте в браузере веб-админку RTP, которая будет доступна по адресу `https://your.domain.ru/rtp-web-admin/`, и введите выданные источником RTP реквизиты.

После успешного входа в сессию, откроется страница, где будут:

- блок видео с удалённого устройства
- чат для общения с удалённем устройством

По умолчанию, источник RTP при входе администратора автоматически запустит трансляцию видео (тестовое видео с шариком при помощи GStreamer).

Доступные команды (их вам также сообщит источник RTP в чате после успешного входа):

- `start`: запуск трансляции видео. Если видео было остановлено, его трансляция и последующее воспроизведение на странице начнётся снова
- `stop`: остановка трансляции видео. Если в данный момент идёт трансляция видео, она прекратится
- `quit`: выход, источник RTP уничтожит текущую сессию и завершит работу. 

Остальные команды источник RTP будет просто дублировать в чат в пометкой "nothing to do".
