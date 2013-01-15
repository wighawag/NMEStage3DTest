package com.wighawag.nme.stage3dtest;

using flash.Vector;
using nme.display3D.Context3DUtils;
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
    var sceneTexture : flash.display3D.textures.Texture;

    var sceneProgram : GLSLProgram;

    var postProcessingProgram : GLSLProgram;

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

        context3D.setRenderCallback(update);

        context3D.setCulling(Context3DTriangleFace.NONE);

        var vertexShaderSource = nme.Assets.getText("assets/vshader.glsl");
        var fragmentShaderSource = nme.Assets.getText("assets/fshader.glsl");
        var vertexShaderAgalInfo : String = nme.Assets.getText("assets/vshader.agal");
        var fragmentShaderAgalInfo : String = nme.Assets.getText("assets/fshader.agal");

        var vertexShader = new GLSLVertexShader(vertexShaderSource);//, vertexShaderAgalInfo);
        var fragmentShader = new GLSLFragmentShader(fragmentShaderSource);//, fragmentShaderAgalInfo);

        sceneProgram = new GLSLProgram(context3D);
        sceneProgram.upload(vertexShader, fragmentShader);


        postProcessingProgram = new GLSLProgram(context3D);
        postProcessingProgram.upload(
            new GLSLVertexShader(nme.Assets.getText("assets/ppros_vshader.glsl")),//,nme.Assets.getText("assets/ppros_vshader.agal")),
            new GLSLFragmentShader(nme.Assets.getText("assets/ppros_fshader.glsl"))//,nme.Assets.getText("assets/ppros_fshader.agal"))
        );


        var logo = Assets.getBitmapData("assets/hxlogo.png");
        texture = context3D.createTexture(logo.width, logo.height, nme.display3D.Context3DTextureFormat.BGRA, false);
        texture.uploadFromBitmapData(logo);


        sceneTexture = context3D.createTexture(nextPowerOfTwo(stage.stageWidth), nextPowerOfTwo(stage.stageHeight), nme.display3D.Context3DTextureFormat.BGRA, false);
    }

    function update() {

        t += 0.01;

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

        sceneProgram.attach();
        sceneProgram.setVertexUniformFromMatrix("proj",mat, true);
        sceneProgram.setTextureAt("texture", texture);
        sceneProgram.setVertexBufferAt("position",vertexBuffer, 0, nme.display3D.Context3DVertexBufferFormat.FLOAT_3);
        sceneProgram.setVertexBufferAt("uv",vertexBuffer, 3, nme.display3D.Context3DVertexBufferFormat.FLOAT_2);


        var indexBuffer = context3D.createIndexBuffer(numIndices);
        indexBuffer.uploadFromByteArray(indexByteArray,0,0, numIndices);



//        context3D.setRenderToTexture(sceneTexture, true);

        context3D.clear(0, 0, 0, 1);
        context3D.drawTriangles(indexBuffer);


//        ////////////////////// POST PROCESSING //////////////////////////
//        context3D.setRenderToBackBuffer();
//
//        var wholeScreenVertices = context3D.createVertexBuffer(4,2);
//        wholeScreenVertices.uploadFromVector(Vector.ofArray([-1.0,1, 1,1, 1,-1, -1,-1 ]),0, 4);
//        postProcessingProgram.attach();
//        postProcessingProgram.setTextureAt("texture", sceneTexture);
//        postProcessingProgram.setVertexBufferAt("position", wholeScreenVertices, 0, nme.display3D.Context3DVertexBufferFormat.FLOAT_2);
//
//        //TODO as part of nme automaticlly:
//        context3D.setVertexBufferAt(1,null);
//
//
//        var wholeScreenIndexBuffer = context3D.createIndexBuffer(6);
//        var screenIndexByteArray = new ByteArray();
//        screenIndexByteArray.endian = Endian.LITTLE_ENDIAN;
//
//        screenIndexByteArray.writeShort(0);
//        screenIndexByteArray.writeShort(2);
//        screenIndexByteArray.writeShort(3);
//
//        screenIndexByteArray.writeShort(0);
//        screenIndexByteArray.writeShort(1);
//        screenIndexByteArray.writeShort(2);
//        wholeScreenIndexBuffer.uploadFromByteArray(screenIndexByteArray, 0, 0, 6);
//
//        context3D.clear(0, 0, 0, 1);
//        context3D.drawTriangles(wholeScreenIndexBuffer);
//        //////////////////////////////////////////////////////////////////


        context3D.present();

    }

    public static function nextPowerOfTwo(v:Int): Int
    {
        v--;
        v |= v >> 1;
        v |= v >> 2;
        v |= v >> 4;
        v |= v >> 8;
        v |= v >> 16;
        v++;
        return v;
    }

}
