# clock
A cron alternative designed for running in a docker container

[![Docker Repository on Quay.io](https://quay.io/repository/s21g/clock/status "Docker Repository on Quay.io")](https://quay.io/repository/s21g/clock)

**USAGE**

It is desined for you to

 * create your own docker container `FROM quay.io/s21g/clock`
 * prepare `./alerm` file that has similar syntax with the crontab
 * build the image and launch a container
