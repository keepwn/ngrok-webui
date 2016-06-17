#!/bin/bash

NGROK_WEBUI_HOST=127.0.0.1
NGROK_WEBUI_PORT=8080
DOCKER_URL=tcp://127.0.0.1:2375
DOCKER_OPTS='"--dns 8.8.8.8 --dns 8.8.4.4 -H '$DOCKER_URL' -H unix://var/run/docker.sock"'
DOMIAN=tunnel.mydomian.com
TUNNEL_PORT=4443
HTTP_PORT=8080
HTTPS_PORT=8081
RUNTIME_DIR=$(pwd)/ngrok-bin
RUNTIME_DIR_IN_CONTAINER=/release


function _color_()
{
    case "$1" in
        red)    nn="31";;
        green)  nn="32";;
        yellow) nn="33";;
        blue)   nn="34";;
        purple) nn="35";;
        cyan)   nn="36";;
    esac
    ff=""
    case "$2" in
        bold)   ff=";1";;
        bright) ff=";2";;
        uscore) ff=";4";;
        blink)  ff=";5";;
        invert) ff=";7";;
    esac
    color_begin=`echo -e -n "\033[${nn}${ff}m"`
    color_end=`echo -e -n "\033[0m"`
    while read line; do
        echo "${color_begin}${line}${color_end}"
    done
}

function _check_requirement_exec_()
{
    # check docker, docker-compose
    echo "->check docker"
    type docker >/dev/null 2>&1 || { echo "docker isn't installed. exit." | _color_ red ; exit 1; }
    echo "->check docker-compose"
    type docker-compose >/dev/null 2>&1 || { echo "docker-compose isn't installed. exit." | _color_ red ; exit 1; }
}

function _check_requirement_env_setting_()
{
    # check docker's configuration
    echo "->check docker's configuration"
    isok=`sed -n "s,DOCKER_OPTS=$DOCKER_OPTS,OK,p" /etc/default/docker`
    if [ -z "$isok" ]; then
        echo "docker's configuration isn't set" | _color_ yellow
        sudo sed -i "s,^#*\(DOCKER_OPTS=.*\),#\1\nDOCKER_OPTS=$DOCKER_OPTS," /etc/default/docker
        echo "set docker's configuration successful" | _color_ green
        sudo service docker restart 2>&1 || { echo "please manually start docker service. exit." | _color_ red ; exit 1; }
        echo "docker's service restarted successful" | _color_ green
    else
        echo "docker's configuration is correct"
    fi
}

function _check_requirement_images_()
{
    # pull docker's images
    echo "will download images, it will take some time depending on your speed" | _color_ yellow
    echo "->pull docker image: alpine"
    docker pull alpine
    echo "->pull docker image: keepwn/ngrok-self-hosting"
    docker pull keepwn/ngrok-self-hosting
    echo "->pull docker image: python:3-alpine"
    docker pull python:3-alpine
    echo "->pull docker image: nginx"
    docker pull nginx
}

function _update_ngrokwebapi_setting_()
{
    # update ngrok-webapi's app.conf
    echo '->update app.conf in ngrok-webapi'
    sed -i "s#^docker_url=.*#docker_url=$DOCKER_URL#" ngrok-webapi/app.conf
    sed -i "s#^server_addr=.*#server_addr=$DOMIAN:$TUNNEL_PORT#" ngrok-webapi/app.conf
    sed -i "s#^runtime_dir=.*#runtime_dir=$RUNTIME_DIR#" ngrok-webapi/app.conf
    sed -i "s#^runtime_dir_in_container=.*#runtime_dir_in_container=$RUNTIME_DIR_IN_CONTAINER#" ngrok-webapi/app.conf
}

function _create_and_start_my_project_()
{
    # create and start
    echo '->create and start project by docker-compose'
    docker-compose -f compose.yaml down
    docker-compose -f compose.yaml up -d
    sleep 5s

    echo '->check ngrok-webapi status'
    code=`curl -o /dev/null -s -w %{http_code} $NGROK_WEBUI_HOST:$NGROK_WEBUI_PORT/service/info`
    if [ "$code" = "200" ]; then
        echo "ngrok-webapi status code is 200" | _color_ green
    else
        echo "ngrok-webapi status isn't correct. exit. please check it." | _color_ red
        exit 1
    fi

    echo '->check ngrok-webui status'
    code=`curl -o /dev/null -s -w %{http_code} $NGROK_WEBUI_HOST:$NGROK_WEBUI_PORT`
    if [ "$code" = "200" ]; then
        echo "ngrok-webui status code is 200" | _color_ green
    else
        echo "ngrok-webui status isn't correct. exit. please check it." | _color_ red
        exit 1
    fi
}

function _check_ngrok_bins_()
{
    findall=`find $RUNTIME_DIR/ngrok $RUNTIME_DIR/ngrokd >/dev/null 2>&1 ; echo $?`
    if [ "$findall" = 0 ]; then
        echo "1"
    else
        echo ""
    fi
}

function _generate_ngrok_bins_()
{
    if [ ! -d "$RUNTIME_DIR" ]; then
        mkdir $RUNTIME_DIR
    fi
    docker run --rm \
        -e DOMAIN="$DOMIAN" \
        -e TUNNEL_PORT=$TUNNEL_PORT \
        -e HTTP_PORT=$HTTP_PORT \
        -e HTTPS_PORT=$HTTPS_PORT \
        -v $RUNTIME_DIR:/release keepwn/ngrok-self-hosting

    echo "check whether the ngrok-bins has been generated"
    if [ $(_check_ngrok_bins_) ]; then
        echo "generate ngrok-bins to $RUNTIME_DIR successful" | _color_ green
    else
        echo "generate ngrok-bins failed, please check it." | _color_ red
        exit 1
    fi
}

function _check_ngrok_server_status_()
{
    echo "->check ngrok-server status"
    nc -w 5 $DOMIAN $TUNNEL_PORT && echo "ngrok-server tunnel port is open" | _color_ green || echo "ngrok-server tunnel port is closed" | _color_ red
    nc -w 5 $DOMIAN $HTTP_PORT && echo "ngrok-server http port is open" | _color_ green || echo "ngrok-server http port is closed" | _color_ red
    nc -w 5 $DOMIAN $HTTPS_PORT && echo "ngrok-server https port is open" | _color_ green || echo "ngrok-server https port is closed" | _color_ red
}


# LET'S GO
echo '0. Checking Env' | _color_ blue invert
_check_requirement_exec_
_check_requirement_env_setting_


echo '1. Downloading Docker Images' | _color_ blue invert
_check_requirement_images_


echo '2. Generating Ngrok-Bin' | _color_ blue invert

if [ ! -d "$RUNTIME_DIR" ] || [ ! $(_check_ngrok_bins_) ]; then
    _generate_ngrok_bins_
else
    echo "the ngrok-bins is already exist, this step will be skipped" | _color_ yellow
fi


echo '3. Creating Ngrok-WebAPI And Ngrok-WebUI' | _color_ blue invert
_update_ngrokwebapi_setting_
_create_and_start_my_project_


echo '4. Need To Do Something Now' | _color_ blue invert

echo "->your ngrok-bins in $RUNTIME_DIR"
echo '->please upload ngrok-bins to your vps' | _color_ yellow
read -s -n1 -p "if you have already done, press any key to continue ..."
_check_ngrok_server_status_


echo '5. Finished. Enjoy The Program' | _color_ blue invert
echo "->your ngrok-webui url is http://$NGROK_WEBUI_HOST:$NGROK_WEBUI_PORT" | _color_ green