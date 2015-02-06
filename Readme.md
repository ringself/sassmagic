###sassmagic
description:Sass extention tool
###install
sudo gem install sassmagic
###use
same to sass
###configuration
sassmagic.json
配置文件:


     {
            "isNeedPxToRem": true,
            "browserDefaultFontSize": "75px",
            "ignore": [
                "1px",
                "[data-dpr=",
                "font-size"
            ],
            "outputExtra": [
                "1x",
                "2x",
                "3x"
            ],
            "imageMaxSize": "5120",
            "imageLoader": "imageuploader.js",
            "imagesPath": {
            },
            "remote":[]
        }

imageuploader.js
图片上传