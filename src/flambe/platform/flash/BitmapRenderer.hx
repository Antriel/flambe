//
// Flambe - Rapid game development
// https://github.com/aduros/flambe/blob/master/LICENSE.txt

package flambe.platform.flash;

import flambe.asset.AssetEntry.AssetFormat;
import flambe.subsystem.RendererSystem.RendererType;
import flambe.util.Value;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.events.Event;
import flash.geom.Rectangle;
import flash.Lib;
import haxe.io.Bytes;

import flambe.display.Texture;

class BitmapRenderer
    implements InternalRenderer<BitmapData>
{
	
	public var type (get, null) :RendererType;
	public var maxTextureSize (get, null) :Int;
	public var hasGPU (get, null) :Value<Bool>;
	public var graphics :InternalGraphics = null;
	
    public function new ()
    {
		_hasGPU = new Value<Bool>(true);
        var stage = Lib.current.stage;

        _bitmap = new Bitmap();
        stage.addChild(_bitmap);

        stage.addEventListener(Event.RESIZE, onResize);
        onResize(null);
    }

    /*public function uploadTexture (texture :Texture)
    {
        // Nothing
    }*/
	
	public function getCompressedTextureFormats () :Array<AssetFormat>
    {
        return [];
    }

    public function createCompressedTexture (format :AssetFormat, data :Bytes) :Texture
    {
        throw "Not supported";
        return null;
    }
	
	inline private function get_type () :RendererType
    {
        return FlashBitmap;
    }
	
	inline private function get_maxTextureSize () :Int
    {
        return 2048; // The max supported by BASELINE_CONSTRAINED
    }
	
	inline private function get_hasGPU () :Value<Bool>
    {
        return _hasGPU;
    }
	
	public function createTexture (width :Int, height :Int) :Texture {
		var root = new BitmapTextureRoot(new BitmapData(width, height, true, 0));
        return root.createTexture(width, height);
	}
	
	public function createTextureFromImage (bitmapData :BitmapData) :Texture {
		var root = new BitmapTextureRoot(bitmapData);
        return root.createTexture(bitmapData.width, bitmapData.height);
	}

    public function willRender ()
    {
        _screen.lock();
    }

    public function didRender ()
    {
        _screen.unlock();
    }

    private function onResize (_)
    {
        if (_screen != null) {
            _screen.dispose();
        }

        var width = _bitmap.stage.stageWidth;
        var height = _bitmap.stage.stageHeight;
        if (width == 0 || height == 0) {
            // In IE, stageWidth and height may initialized to zero! A resize event will come in
            // after a couple frames to give us the real dimensions, use a fixed size until then.
            // http://jodieorourke.com/view.php?id=79&blog=news
            width = height = 100;
        }

        _screen = new BitmapData(width, height, true, 0);
        graphics = new BitmapGraphics(_screen);
        _bitmap.bitmapData = _screen;
    }

    private var _screen :BitmapData;
    private var _bitmap :Bitmap;
	private var _hasGPU :Value<Bool>;
}