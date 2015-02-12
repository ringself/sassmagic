### sassmagic


description:Sass extention tool


### install


sudo gem install sassmagic


### use

start:

####sassmagic init

or  

####sassmagic creat [project]

other

same to sass

eg: sassmagic --style nested --x test.scss test.css

### configuration


sassmagic.json 配置文件:




     {
            "isNeedPxToRem": true,//是否自动转rem
            "browserDefaultFontSize": "75px",//rem设置
            "devicePixelRatio":"2",//dpr设置
            "ignore": [//过滤不需要转rem的内容
                "1px",
                "[data-dpr=",
                "font-size"
            ],
            "outputExtra": [//额外输出1x 2x 3x样式表
                "1x",
                "2x",
                "3x"
            ],
            "imageMaxSize": "5120",//图片时候上传阀值
            "imageLoader": "../config/imageuploader.js",//上传任务nodeJs
            "imagesPath": {//上传文件缓存
            },
            "remoteStylesheet":"",//远程stylesheet路径
            "tinypngKye",""//tinypngApiKey
        }

imageuploader.js
图片上传
