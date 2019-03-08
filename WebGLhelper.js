function getShader(gl, id) {
    var shaderScript = document.getElementById(id);
    var str = "";
    var k = shaderScript.firstChild;
    while (k) {
        if (k.nodeType == 3) str += k.textContent;
        k = k.nextSibling;
    }
    var shader;
    if (shaderScript.type == "x-shader/x-fragment")
        shader = gl.createShader(gl.FRAGMENT_SHADER);
    else if (shaderScript.type == "x-shader/x-vertex")
        shader = gl.createShader(gl.VERTEX_SHADER);
    else return null;
    gl.shaderSource(shader, str);
    gl.compileShader(shader);
    if (gl.getShaderParameter(shader, gl.COMPILE_STATUS) == 0)
        alert(gl.getShaderInfoLog(shader));


    return shader;
}

function getShaderFromFile(gl, url, type) {
    var req = new XMLHttpRequest();
    req.open("GET", url, false);
    req.send(null);

    var shader = null;
    if (req.status == 200 || req.status == 0) {

        shader = gl.createShader(type);

        gl.shaderSource(shader, req.responseText);

        gl.compileShader(shader);
        if (gl.getShaderParameter(shader, gl.COMPILE_STATUS) == 0)
            console.error(gl.getShaderInfoLog(shader));
    }

    return shader;
}





function xhrSuccess() {this.callback.apply(this,this.arguments); }


function xhrError()
{
    console.error(this.statusText);
}

function getShaderFromFileAsync(url, func)
{

    var req = new XMLHttpRequest();
    req.callback = func;
    req.open("GET", url, true);
    req.arguments= Array.prototype.slice.call(arguments,2);
    req.onload = xhrSuccess;
    req.onerror = xhrError;
    req.send(null);

}




function textureFromArray(ctx, dataArray, type, width, height) {
    var dataTypedArray = new Uint8Array(dataArray); // Don't need to do this if the data is already in a typed array
    var texture = ctx.createTexture();
    ctx.activeTexture(ctx.TEXTURE0);
    ctx.bindTexture(ctx.TEXTURE_2D, texture);
    ctx.texImage2D(ctx.TEXTURE_2D, 0, type, width, height, 0, type, ctx.UNSIGNED_BYTE, dataTypedArray);
    ctx.texParameteri(ctx.TEXTURE_2D, ctx.TEXTURE_MAG_FILTER, ctx.NEAREST);
    ctx.texParameteri(ctx.TEXTURE_2D, ctx.TEXTURE_MIN_FILTER, ctx.NEAREST);
    // Other texture setup here, like filter modes and mipmap generation
    return texture;
}

// Loads a texture from the absolute or relative URL "src".
// Returns a WebGLTexture object.
// The texture is downloaded in the background using the browser's
// built-in image handling. Upon completion of the download, our
// onload event handler will be called which uploads the image into
// the WebGLTexture.
function loadTexture(gl, src) {
    // Create and initialize the WebGLTexture object.
    var texture = gl.createTexture();
    gl.bindTexture(gl.TEXTURE_2D, texture);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
    // Create a DOM image object.
    var image = new Image();
    // Set up the onload handler for the image, which will be called by
    // the browser at some point in the future once the image has
    // finished downloading.
    image.onload = function () {
        // This code is not run immediately, but at some point in the
        // future, so we need to re-bind the texture in order to upload
        // the image. Note that we use the JavaScript language feature of
        // closures to refer to the "texture" and "image" variables in the
        // containing function.
        gl.bindTexture(gl.TEXTURE_2D, texture);
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, image);
        render();
        //checkGLError();
        //draw()
    };
    // Start downloading the image by setting its source.
    image.src = src;
    // Return the WebGLTexture object immediately.
    return texture;
}


function loadImage(url, callback) {
    var image = new Image();
    image.src = url;
    image.onload = callback;
    return image;
}

function loadImages(urls, callback) {
    var images = [];
    var imagesToLoad = urls.length;

    // Called each time an image finished
    // loading.
    var onImageLoad = function () {
        --imagesToLoad;
        // If all the images are loaded call the callback.
        if (imagesToLoad == 0) {
            callback(images);
        }
    };

    for (var ii = 0; ii < imagesToLoad; ++ii) {
        var image = loadImage(urls[ii], onImageLoad);
        images.push(image);
    }
}