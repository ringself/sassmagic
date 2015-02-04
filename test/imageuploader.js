var uploader = require('@ali/or-uploadimg');
var fs = require('fs');
var path = require('path');
var file = process.argv[2]
var imgList = process.argv[3] || []

//参数输出
//process.argv.forEach(function (val, index, array) {
//    console.log(index + ': ' + val);
//});

fs.readFile(file, 'utf8', function(err, data) {
    if(err) {
        return console.log(err);
    }
    //console.log(data);
    var config = JSON.parse(data);
    config.imagesPath = config.imagesPath || {}
    uploader(imgList, function (list) {
        //console.log(list)
        list.forEach(function(v,i){
            for(var i in v){
                //console.log(v)
                config.imagesPath[i] = v[i]
            }
        })
        //console.log(config);
        //写文件
        fs.writeFile(file, JSON.stringify(config,null,4), function(err) {
            if(err) {
                return console.log(err);
            }
            //console.log('writing done');
        })
    });



})