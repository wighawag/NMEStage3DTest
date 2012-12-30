package hxsl.samples.utils;
class HXSLVector {

    public var x : Float;
    public var y : Float;
    public var z : Float;

    public function new( x = 0., y = 0., z = 0. ) {
        this.x = x;
        this.y = y;
        this.z = z;
    }

    public inline function sub( v : HXSLVector ) {
        return new HXSLVector(x - v.x, y - v.y, z - v.z);
    }

    public inline function add( v : HXSLVector ) {
        return new HXSLVector(x + v.x, y + v.y, z + v.z);
    }

    public inline function cross( v : HXSLVector ) {
        return new HXSLVector(y * v.z - z * v.y, z * v.x - x * v.z,  x * v.y - y * v.x);
    }

    public inline function dot( v : HXSLVector ) {
        return x * v.x + y * v.y + z * v.z;
    }

    public inline function length() {
        return Math.sqrt(x * x + y * y + z * z);
    }

    public function normalize() {
        var k = length();
        if( k < Const.EPSILON ) k = 0 else k = 1.0 / k;
        x *= k;
        y *= k;
        z *= k;
    }

    public function set(x,y,z) {
        this.x = x;
        this.y = y;
        this.z = z;
    }

    public inline function scale( f : Float ) {
        x *= f;
        y *= f;
        z *= f;
    }

    public inline function project3x3( m : Matrix ) {
        var px = x * m._11 + y * m._12 + z * m._13;
        var py = x * m._21 + y * m._22 + z * m._23;
        var pz = x * m._31 + y * m._32 + z * m._33;
        x = px;
        y = py;
        z = pz;
    }

    public inline function copy() {
        return new HXSLVector(x,y,z);
    }

    public function toString() {
        return "{"+Const.f(x)+","+Const.f(y)+","+Const.f(z)+"}";
    }


}