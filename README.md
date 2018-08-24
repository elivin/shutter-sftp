# SftpUpload - загрузка скриншотов по sftp

SftpUpload - плагин для [Shutter](http://shutter-project.org/). Предназначен для загрузки скриншотов на свой сервер по sftp. Поддерживает авторизацию как по паролю, так и ключом.

## Зависимости

Плагин использует пакет [Net::SFTP::Foreign](https://metacpan.org/pod/Net::SFTP::Foreign). Соответственно, его нужно установить. В debian-подобных ОС можно выполнить установку так:

```bash
apt-get install libnet-sftp-foreign-perl
```

Остальные используемые пакеты тянет за собой сам Shutter.

## Установка и настройка

Для установки плагина скопируйте файл SftpUpload.pm в директорию **/usr/share/shutter/resources/system/upload_plugins/upload** и дайте права на выполнение

```bash
chmod +x /usr/share/shutter/resources/system/upload_plugins/upload/SftpUpload.pm
```

В домашней директории нужно создать файл **.config/shutter-sftp.json** примерно такого вида:

```json
{
    "host": "sftp.server.ru",
    "directory": "/home/user/files/screen",
    "link": "http://sftp.server.ru/screen",
    "username": "user",
    "password": "password",
    "key": "/home/user/.ssh/id_rsa",
    "passphrase": "key-passphrase"
}
```

Где:

| Опция      | Обязателен | Описание |
| ---------- | ---------- | -------- |
| host       | Да         | Доменное имя или IP-адрес sftp-сервера |
| directory  | Да         | Директория на сервере, куда будет загружено изображение |
| link       | Да         | Начало ссылки, к которому будет добавлено имя файла скриншота. Без последнего слеша |
| username   | Нет        | Имя пользователя. Можно указать не в конфиге, а в настройках shutter |
| password   | Нет        | Пароль. Можно указать не в конфиге, а в настройках shutter. При авторизации по ключу указывать не нужно |
| key        | Нет        | Путь до файла с закрытым ключом, если используется авторизация по ключу |
| passphrase | Нет        | Пароль от ключа. Пока не нашёл другого способа хранить его, кроме как в файле |

После этого перезапускаем Shutter. В вариантах экспорта должен появиться пункт SftpUpload.
