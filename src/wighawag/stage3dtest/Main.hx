package wighawag.stage3dtest;

import flash.events.ErrorEvent;
using flash.Vector;
using flash.display3D.Context3DUtils;
import flash.display3D.Context3DTriangleFace;
import flash.display3D.Context3DCompareMode;
import flash.display3D.Program3D;
import flash.utils.Endian;
import flash.utils.ByteArray;
import flash.display.BitmapData;
import openfl.Assets;

import hxsl.samples.utils.Camera;
import flash.display3D.Context3DProgramType;
import flash.display3D.shaders.glsl.GLSLProgram;
import flash.display3D.shaders.glsl.GLSLVertexShader;
import flash.display3D.shaders.glsl.GLSLFragmentShader;

import flash.ui.Keyboard;

class Main{

	public static function main() : Void{
        var inst = new Main();
	}

    var stage : flash.display.Stage;
    var stage3D : flash.display.Stage3D;
    var context3D : flash.display3D.Context3D;
    var keys : Array<Bool>;
    var texture : flash.display3D.textures.Texture;
    var sceneTexture : flash.display3D.textures.Texture;

    var sceneProgram : GLSLProgram;

    var postProcessingProgram : GLSLProgram;

    var camera : Camera;
    var t : Float;

    public function new() {
        t = 0;
        keys = [];
        stage = flash.Lib.current.stage;
        stage3D = stage.stage3Ds[0];
        stage3D.addEventListener( flash.events.Event.CONTEXT3D_CREATE, onReady );
        stage3D.addEventListener( flash.events.ErrorEvent.ERROR, onError );
        stage.addEventListener( flash.events.KeyboardEvent.KEY_DOWN, onKey.bind(true) );
        stage.addEventListener( flash.events.KeyboardEvent.KEY_UP, onKey.bind(false) );
        stage3D.requestContext3D();
    }

    function onError(event : ErrorEvent) : Void{
        trace(event);
    }

    function onKey( down, e : flash.events.KeyboardEvent ) {
        keys[e.keyCode] = down;
    }

    function onReady( _ ) {
        context3D = stage3D.context3D;

        context3D.configureBackBuffer( stage.stageWidth, stage.stageHeight, 0, false );

        camera = new Camera();

        context3D.enableErrorChecking = true;



        //context3D.setCulling(Context3DTriangleFace.NONE);

        //var vertexShaderSource = flash.Assets.getText("assets/vshader.glsl");
        var vertexShaderSource = "attribute vec3 position;\n"+
        "attribute vec2 uv;\n"+
        "uniform mat4 proj;\n"+
        "varying vec2 vTexCoord;\n"+
        "void main() {\n"+
            "gl_Position = proj * vec4(position, 1.0);\n"+
            "vTexCoord = uv;\n"+
        "}";
        //var fragmentShaderSource = flash.Assets.getText("assets/fshader.glsl");
        var fragmentShaderSource = #if js "precision mediump float;\n"+ #end
        "varying vec2 vTexCoord;\n"+
        "uniform sampler2D texture;\n"+
        "void main() {\n"+
            "vec4 texColor = texture2D(texture, vTexCoord);\n"+
            "gl_FragColor = texColor;\n"+
        "}";
        //var vertexShaderAgalInfo : String = flash.Assets.getText("assets/vshader.agal");
        //var fragmentShaderAgalInfo : String = flash.Assets.getText("assets/fshader.agal");

        var vertexShader = new GLSLVertexShader(vertexShaderSource);//, vertexShaderAgalInfo);
        var fragmentShader = new GLSLFragmentShader(fragmentShaderSource);//, fragmentShaderAgalInfo);

        sceneProgram = new GLSLProgram(context3D);
        sceneProgram.upload(vertexShader, fragmentShader);


        //flash.Assets.getText("assets/ppros_vshader.glsl")
        //flash.Assets.getText("assets/ppros_fshader.glsl")
        var pprosVShaderSource = "const vec2 madd=vec2(0.5,0.5);\n"+
        "attribute vec4 position;\n"+
        "varying vec2 vTexCoord;\n"+
        "void main() {\n"+
            "gl_Position = position;\n"+
            "vec2 t = vec2(position.xy  * madd + madd);\n"+
//"t.y = 1 -t.y; reverse does not work in glsl\n"+
            "vTexCoord = t;\n"+
        "}";
        var pprosFShaderSource = #if js "precision mediump float;\n"+ #end
        "varying vec2 vTexCoord;\n"+
        "uniform sampler2D texture;\n"+
        "void main() {\n"+
            "vec4 texColor = texture2D(texture, vTexCoord);\n"+
            "texColor.y = 0.0;\n"+
            "texColor.z = 0.0;\n"+
            "gl_FragColor = texColor;\n"+
        "}";
        postProcessingProgram = new GLSLProgram(context3D);
        postProcessingProgram.upload(
            new GLSLVertexShader(pprosVShaderSource),//,flash.Assets.getText("assets/ppros_vshader.agal")),
            new GLSLFragmentShader(pprosFShaderSource)//,flash.Assets.getText("assets/ppros_fshader.agal"))
        );

        var logo = Assets.getBitmapData("assets/hxlogo.png");

        //var bitmap = new flash.display.Bitmap(logo);
        //flash.Lib.current.stage.addChild(bitmap);
        //var sprite = new flash.display.Sprite();
        //sprite.graphics.beginFill(0xff0000);
        //sprite.graphics.drawRect(0,0,100,100);
        //sprite.graphics.endFill();
        //flash.Lib.current.stage.addChild(sprite);

        texture = context3D.createTexture(logo.width, logo.height, flash.display3D.Context3DTextureFormat.BGRA, false);

        texture.uploadFromBitmapData(logo);

        sceneTexture = context3D.createTexture(nextPowerOfTwo(stage.stageWidth), nextPowerOfTwo(stage.stageHeight), flash.display3D.Context3DTextureFormat.BGRA, false);

        context3D.setRenderCallback(update);
    }

    function update(event : flash.events.Event) {

        t += 0.01;

        //context3D.setDepthTest(true,Context3DCompareMode.LESS);

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

        var mpos = new flash.geom.Matrix3D();
        mpos.appendRotation(t * 10, flash.geom.Vector3D.Z_AXIS);


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
        context3D.setGLSLSamplerStateAt("texture",flash.display3D.Context3DWrapMode.CLAMP, flash.display3D.Context3DTextureFilter.LINEAR, flash.display3D.Context3DMipFilter.MIPNONE);
        sceneProgram.setTextureAt("texture", texture);
        sceneProgram.setVertexBufferAt("position",vertexBuffer, 0, flash.display3D.Context3DVertexBufferFormat.FLOAT_3);
        sceneProgram.setVertexBufferAt("uv",vertexBuffer, 3, flash.display3D.Context3DVertexBufferFormat.FLOAT_2);


        var indexBuffer = context3D.createIndexBuffer(numIndices);
        indexBuffer.uploadFromByteArray(indexByteArray,0,0, numIndices);


        if (shouldRenderToTexture()){
            context3D.setRenderToTexture(sceneTexture);
        }


        context3D.clear(0, 0.2, 0, 1);
        context3D.drawTriangles(indexBuffer);


        if(shouldRenderToTexture()){
            ////////////////////// POST PROCESSING //////////////////////////
            context3D.setRenderToBackBuffer();

            var wholeScreenVertices = context3D.createVertexBuffer(4,2);
            wholeScreenVertices.uploadFromVector(Vector.ofArray([-1.0,1, 1,1, 1,-1, -1,-1 ]),0, 4);
            postProcessingProgram.attach();
            postProcessingProgram.setTextureAt("texture", sceneTexture);
            postProcessingProgram.setVertexBufferAt("position", wholeScreenVertices, 0, flash.display3D.Context3DVertexBufferFormat.FLOAT_2);

            //TODO as part of flash.automatically:
            #if flash
            context3D.setVertexBufferAt(1,null);
            #end


            var wholeScreenIndexBuffer = context3D.createIndexBuffer(6);
            var screenIndexByteArray = new ByteArray();
            screenIndexByteArray.endian = Endian.LITTLE_ENDIAN;

            screenIndexByteArray.writeShort(0);
            screenIndexByteArray.writeShort(2);
            screenIndexByteArray.writeShort(3);

            screenIndexByteArray.writeShort(0);
            screenIndexByteArray.writeShort(1);
            screenIndexByteArray.writeShort(2);
            wholeScreenIndexBuffer.uploadFromByteArray(screenIndexByteArray, 0, 0, 6);

            context3D.clear(0.5, 0, 0, 1);
            context3D.drawTriangles(wholeScreenIndexBuffer);
            //////////////////////////////////////////////////////////////////
        }

        context3D.present();

    }



    private function shouldRenderToTexture() : Bool{
        return keys[Keyboard.SPACE];
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
