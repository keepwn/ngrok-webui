# ngrok-webui
simple webui for ngrok

## Introduction
这是一款WebUI版的Ngrok工具

摒弃了命令行式管理，可以方便地通过浏览器对Ngrok进行各种管理。

你也可以将本工具的Web端口映射到公网，这样你在访问不到内网的时候，依旧可以通过浏览器对其进行管理。

## Requirement
- [docker](https://docs.docker.com/linux/)
- [docker-compose](https://docs.docker.com/compose/install/)
- [ngrok 1.x](https://github.com/inconshreveable/ngrok)
  - 不需要自己提供，安装脚本会自动下载并编译
- ubuntu 14.04
  - 其他系统未做测试，不保证完整可用

## Run
```bash
git clone --recursive https://github.com/keepwn/ngrok-webui.git my-ngrok
cd my-ngrok
./run.sh
```
在运行`run.sh`之前，请先修改`run.sh`里的环境变量

## Environment Variables
| variables        |        default        | meaning                  | change |
| ---------------- | :-------------------: | ------------------------ | ------ |
| NGROK_WEBUI_HOST |      `127.0.0.1`      | webui的监听地址               | 不建议修改  |
| NGROK_WEBUI_PORT |        `8080`         | webui的监听端口               | 不建议修改  |
| DOMAIN           | `tunnel.mydomian.com` | ngrok server的监听地址        | 必须修改   |
| TUNNEL_PORT      |        `4443`         | ngrok server的监听端口        | 可修改    |
| HTTP_PORT        |         `80`          | ngrok server提供HTTP服务的端口  | 可修改    |
| HTTPS_PORT       |         `443`         | ngrok server提供HTTPS服务的端口 | 可修改    |

## Developing
本工具由`Ngrok-WebAPI`和`Ngrok-WebUI`两部分组成。其中：
- `Ngrok-WebAPI`
  - 提供ngrok的webapi功能
  - 实现了将ngrok命令行下的功能转化为`RESTful`风格的API
  - 由`Python3`实现
- `Ngrok-WebUI`
  - 提供ngrok的webui功能
  - 通过调用ngrok-webapi来管理ngrok
  - 由`Vue.js`+`webpack`实现

具体原理图如下：

![原理图](https://raw.githubusercontent.com/keepwn/ngrok-webui/master/doc/image.png)
