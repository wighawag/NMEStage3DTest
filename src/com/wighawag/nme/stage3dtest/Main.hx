package com.wighawag.nme.stage3dtest;

import flash.display3D.Context3DTriangleFace;
import flash.display3D.Context3DCompareMode;
import flash.display3D.Program3D;
import flash.utils.Endian;
import flash.utils.ByteArray;
import nme.Assets;

import hxsl.samples.utils.Camera;
import nme.display3D.Context3DProgramType;
import nme.display3D.shaders.glsl.GLSLProgram;
import nme.display3D.shaders.glsl.GLSLVertexShader;
import nme.display3D.shaders.glsl.GLSLFragmentShader;

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

    var glslProgram : GLSLProgram;

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

        context3D.enableErrorChecking = true;

        #if flash
        nme.Lib.current.addEventListener(nme.events.Event.ENTER_FRAME, update);
        #elseif cpp
        context3D.setRenderMethod(update);
        #end

        context3D.setCulling(Context3DTriangleFace.NONE);

        var vertexShaderSource = nme.Assets.getText("assets/vshader.glsl");
        var fragmentShaderSource = nme.Assets.getText("assets/fshader.glsl");
        var vertexShaderAgalInfo : String = nme.Assets.getText("assets/vshader.agal");
        var fragmentShaderAgalInfo : String = nme.Assets.getText("assets/fshader.agal");

        var vertexShader = new GLSLVertexShader(vertexShaderSource, vertexShaderAgalInfo);
        var fragmentShader = new GLSLFragmentShader(fragmentShaderSource, fragmentShaderAgalInfo);

        glslProgram = new GLSLProgram(context3D);
        glslProgram.upload(vertexShader, fragmentShader);

        var logo = Assets.getBitmapData("assets/hxlogo.png");
        texture = context3D.createTexture(logo.width, logo.height, nme.display3D.Context3DTextureFormat.BGRA, false);
        texture.uploadFromBitmapData(logo);

    }

    function update(value : Dynamic) {


        t += 0.01;

        context3D.clear(0, 0, 0, 1);

        context3D.setDepthTest(true,Context3DCompareMode.LESS);

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

        glslProgram.attach();
        glslProgram.setVertexUniformFromMatrix("proj",mat, true);
        glslProgram.setTextureAt("texture", texture);
        glslProgram.setVertexBufferAt("position",vertexBuffer, 0, nme.display3D.Context3DVertexBufferFormat.FLOAT_3);
        glslProgram.setVertexBufferAt("uv",vertexBuffer, 3, nme.display3D.Context3DVertexBufferFormat.FLOAT_2);


        var indexBuffer = context3D.createIndexBuffer(numIndices);
        indexBuffer.uploadFromByteArray(indexByteArray,0,0, numIndices);


        //context3D.drawTriangles(indexBuffer, 0, Std.int(numVertices /2));
        context3D.drawTriangles(indexBuffer);

        context3D.present();

    }

}
