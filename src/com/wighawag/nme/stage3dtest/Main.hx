package com.wighawag.nme.stage3dtest;

import flash.display3D.Program3D;
import flash.utils.Endian;
import flash.utils.ByteArray;
import nme.Assets;

import hxsl.samples.utils.Camera;
import nme.display3D.Context3DUtils;
import nme.display3D.Context3DProgramType;


import nme.ui.Keyboard;

class Main{
	public static function main() : Void{
        var inst = new Main();
	}

    var stage : nme.display.Stage;
    var stage3D : nme.display.Stage3D;
    var context3D : flash.display3D.Context3D;
    var keys : Array<Bool>;
    var texture : flash.display3D.textures.Texture;

    var program3D : Program3D;

    var camera : Camera;
    var t : Float;

    function new() {
        t = 0;
        keys = [];
        stage = flash.Lib.current.stage;
        stage3D = stage.stage3Ds[0];
        stage3D.addEventListener( nme.events.Event.CONTEXT3D_CREATE, onReady );
        stage.addEventListener( nme.events.KeyboardEvent.KEY_DOWN, callback(onKey,true) );
        stage.addEventListener( nme.events.KeyboardEvent.KEY_UP, callback(onKey,false) );
        stage3D.requestContext3D();
    }

    function onKey( down, e : nme.events.KeyboardEvent ) {
        keys[e.keyCode] = down;
    }

    function onReady( _ ) {
        context3D = stage3D.context3D;

        context3D.configureBackBuffer( stage.stageWidth, stage.stageHeight, 0, true );


        camera = new Camera();

        #if flash
        nme.Lib.current.addEventListener(nme.events.Event.ENTER_FRAME, update);
        context3D.enableErrorChecking = true;
        #elseif cpp
        context3D.setRenderMethod(update);
        #end


        #if flash
        var vertexShaderSource =
        [
        "m44 op, va0, vc0",
		"mov v0, va1"
		 ].join("\n");
        var fragmentShaderSource =
        [
        "mov ft0, v0",
		"tex ft1, ft0, fs0 <2d,clamp,linear>",
		"mov oc, ft1"
        ].join("\n");
        #elseif cpp
        var vertexShaderSource =
            "attribute vec3 va0;" +
            "attribute vec2 va1;" +
            "uniform mat4 vc0;" +
            "varying vec2 vTexCoord;" +
            "void main() {" +
            " gl_Position = vc0 * vec4(va0, 1.0);" +
            " vTexCoord = va1;" +
            "}";
        var fragmentShaderSource =
            "varying vec2 vTexCoord;" +
            "uniform sampler2D fs0;" +
            "void main() {" +
            "vec4 texColor = texture2D(fs0, vTexCoord);" +
            "gl_FragColor = texColor;"+
            "}";
        #end


        program3D = context3D.createProgram();
        var vShader = Context3DUtils.createShader(Context3DProgramType.VERTEX, vertexShaderSource);
        var fShader = Context3DUtils.createShader(Context3DProgramType.FRAGMENT, fragmentShaderSource);
        program3D.upload(vShader, fShader);

        var logo = Assets.getBitmapData("assets/hxlogo.png");
        texture = context3D.createTexture(logo.width, logo.height, nme.display3D.Context3DTextureFormat.BGRA, false);
        texture.uploadFromBitmapData(logo);

    }

    function update(value : Dynamic) {


        t += 0.01;

        context3D.clear(0, 0, 0, 1);

        if( keys[Keyboard.UP] )
            camera.moveAxis(0,-0.1);
        if( keys[Keyboard.DOWN] )
            camera.moveAxis(0,0.1);
        if( keys[Keyboard.LEFT] )
            camera.moveAxis(-0.1,0);
        if( keys[Keyboard.RIGHT] )
            camera.moveAxis(0.1, 0);
        if( keys[109] )
            camera.zoom /= 1.05;
        if( keys[107] )
            camera.zoom *= 1.05;
        camera.update();

        var project = camera.m.toMatrix();

        var mpos = new nme.geom.Matrix3D();
        mpos.appendRotation(t * 10, nme.geom.Vector3D.Z_AXIS);


        project.prepend(mpos);
        var mat = project;

        var vertexByteArray = new ByteArray();
        vertexByteArray.endian = Endian.LITTLE_ENDIAN;

        var x= 1;
        var y= 1;
        var z= 1;

        vertexByteArray.writeFloat(0);
        vertexByteArray.writeFloat(0);
        vertexByteArray.writeFloat(0);

        vertexByteArray.writeFloat(0);
        vertexByteArray.writeFloat(0);


        vertexByteArray.writeFloat(x);
        vertexByteArray.writeFloat(0);
        vertexByteArray.writeFloat(0);

        vertexByteArray.writeFloat(1);
        vertexByteArray.writeFloat(0);



        vertexByteArray.writeFloat(0);
        vertexByteArray.writeFloat(y);
        vertexByteArray.writeFloat(0);

        vertexByteArray.writeFloat(0);
        vertexByteArray.writeFloat(1);


        vertexByteArray.writeFloat(x);
        vertexByteArray.writeFloat(y);
        vertexByteArray.writeFloat(0);

        vertexByteArray.writeFloat(1);
        vertexByteArray.writeFloat(1);


        var indexByteArray = new ByteArray();
        indexByteArray.endian = Endian.LITTLE_ENDIAN;

        indexByteArray.writeShort(0);
        indexByteArray.writeShort(2);
        indexByteArray.writeShort(1);

        indexByteArray.writeShort(1);
        indexByteArray.writeShort(3);
        indexByteArray.writeShort(2);

        var dataPerVertex = 5;
        var numIndices = Std.int(indexByteArray.position / 2);
        var numVertices = Std.int(vertexByteArray.position / (4 *dataPerVertex));


        var vertexBuffer = context3D.createVertexBuffer(numVertices, dataPerVertex);
        vertexBuffer.uploadFromByteArray(vertexByteArray, 0, 0, numVertices);


        context3D.setProgram(program3D);
        context3D.setProgramConstantsFromMatrix(nme.display3D.Context3DProgramType.VERTEX, 0, mat, true);
        context3D.setTextureAt( 0, texture);
        context3D.setVertexBufferAt(0, vertexBuffer, 0, flash.display3D.Context3DVertexBufferFormat.FLOAT_3);
        context3D.setVertexBufferAt(1, vertexBuffer, 3, flash.display3D.Context3DVertexBufferFormat.FLOAT_2);



        var indexBuffer = context3D.createIndexBuffer(numIndices);
        indexBuffer.uploadFromByteArray(indexByteArray,0,0, numIndices);


        //context3D.drawTriangles(indexBuffer, 0, Std.int(numVertices /2));
        context3D.drawTriangles(indexBuffer);

        context3D.present();
    }

}
