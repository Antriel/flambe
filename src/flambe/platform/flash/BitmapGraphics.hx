//
// Flambe - Rapid game development
// https://github.com/aduros/flambe/blob/master/LICENSE.txt

package flambe.platform.flash;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Graphics;
import flash.display.Shape;
import flash.geom.ColorTransform;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.Lib;
import haxe.ds.GenericStack;

import flambe.display.BlendMode;
import flambe.display.Texture;
import flambe.math.FMath;

class BitmapGraphics
    implements InternalGraphics
{
    public function new (buffer :BitmapData)
    {
        _buffer = buffer;
        _stack = new GenericStack<DrawingState>();
		save();
        _shape = new Shape();
        _pixel = new BitmapData(1, 1, false);
        _scratchRect = new Rectangle();
        _scratchPoint = new Point();
        _scratchMatrix = new Matrix();
    }
	
	public function applyScissor (x :Float, y :Float, width :Float, height :Float)
    {
        throw "Not implemented";
    }
	
	public function willRender ()
    {
        // Nothing at all
    }

    public function didRender ()
    {
        // Nothing at all
    }
	
	public function onResize (width :Int, height :Int)
    {
        // Nothing at all
    }
	
	public function setAlpha (alpha :Float) {
		getTopState().color.alphaMultiplier = alpha;
	}

    public function save ()
    {
        var copy = new DrawingState();

        if (_stack.isEmpty()) {
            copy.matrix = new Matrix();
        } else {
            var state = getTopState();
            copy.matrix = state.matrix.clone();
            copy.blendMode = state.blendMode;
            if (state.color != null) {
                copy.color = new ColorTransform(1, 1, 1, state.color.alphaMultiplier);
            }
        }

        _stack.add(copy);
    }

    public function translate (x :Float, y :Float)
    {
        flushGraphics();

        var matrix = getTopState().matrix;
        matrix.tx += matrix.a*x + matrix.c*y;
        matrix.ty += matrix.b*x + matrix.d*y;
    }

    public function scale (x :Float, y :Float)
    {
        flushGraphics();

        var matrix = getTopState().matrix;
        matrix.a *= x;
        matrix.b *= x;
        matrix.c *= y;
        matrix.d *= y;
    }

    public function rotate (rotation :Float)
    {
        flushGraphics();

        var matrix = getTopState().matrix;
        rotation = FMath.toRadians(rotation);
        var sin = Math.sin(rotation);
        var cos = Math.cos(rotation);
        var a = matrix.a;
        var b = matrix.b;
        var c = matrix.c;
        var d = matrix.d;

        matrix.a = a*cos + c*sin;
        matrix.b = b*cos + d*sin;
        matrix.c = c*cos - a*sin;
        matrix.d = d*cos - b*sin;
    }

    public function restore ()
    {
        flushGraphics();
        _stack.pop();
    }
	
	public function transform (m00 :Float, m10 :Float, m01 :Float, m11 :Float, m02 :Float, m12 :Float)
    {
		var matrix = getTopState().matrix;
		_scratchMatrix.a = m00;
		_scratchMatrix.b = m10;
		_scratchMatrix.c = m01;
		_scratchMatrix.d = m11;
		_scratchMatrix.tx = m02;
		_scratchMatrix.ty = m12;
		_scratchMatrix.concat(matrix);
		matrix.copyFrom(_scratchMatrix);
    }

    public function drawTexture (texture :Texture, destX :Float, destY :Float) {
        blit(texture, destX, destY, null);
    }

    public function drawSubTexture (texture :Texture, destX :Float, destY :Float,
			sourceX :Float, sourceY :Float, sourceW :Float, sourceH :Float) {
        _scratchRect.x = sourceX;
        _scratchRect.y = sourceY;
        _scratchRect.width = sourceW;
        _scratchRect.height = sourceH;
        blit(texture, destX, destY, _scratchRect);
    }

    public function drawPattern (texture :Texture, x :Float, y :Float, width :Float, height :Float)
    {
        beginGraphics();

        var flashTexture = Lib.as(texture, BitmapTexture);
		var root = flashTexture.root;
		root.assertNotDisposed();
        _graphics.beginBitmapFill(root.image);
        _graphics.drawRect(x, y, width, height);
    }

    public function fillRect (color :Int, x :Float, y :Float, width :Float, height :Float)
    {
        flushGraphics();

        var state = getTopState();
        var matrix = state.matrix;

        // Does this matrix not involve rotation or blending?
        if (matrix.b == 0 && matrix.c == 0 && state.blendMode == null) {
            var scaleX = matrix.a;
            var scaleY = matrix.d;
            var rect = _scratchRect;
            rect.x = matrix.tx + x*scaleX;
            rect.y = matrix.ty + y*scaleY;
            rect.width = width*scaleX;
            rect.height = height*scaleY;

            // fillRect and colorTransform don't support negative rectangles
            if (rect.width < 0) {
                rect.width = -rect.width;
                rect.x -= rect.width;
            }
            if (rect.height < 0) {
                rect.height = -rect.height;
                rect.y -= rect.height;
            }

            // If we don't need to alpha blend, use fillRect(), otherwise colorTransform()
            if (state.color == null) {
                _buffer.fillRect(rect, color);

            } else {
                var red = 0xff & (color >> 16);
                var green = 0xff & (color >> 8);
                var blue = 0xff & (color);
                var alpha = state.color.alphaMultiplier;
                var invAlpha = 1-alpha;
                var transform = new ColorTransform(invAlpha, invAlpha, invAlpha, 1,
                    alpha*red, alpha*green, alpha*blue);
                _buffer.colorTransform(rect, transform);
            }

        } else {
            // Fall back to slowpoke draw() to draw a scaled and translated pixel
            _scratchMatrix.a = width;
            _scratchMatrix.b = 0;
            _scratchMatrix.c = 0;
            _scratchMatrix.d = height;
            _scratchMatrix.tx = x;
            _scratchMatrix.ty = y;
            _scratchMatrix.concat(matrix);

            _pixel.setPixel(0, 0, color);
            _buffer.draw(_pixel, _scratchMatrix, state.color, state.blendMode);
        }
    }

    public function multiplyAlpha (factor :Float)
    {
        flushGraphics();

        var state = getTopState();
        if (state.color == null) {
            state.color = new ColorTransform(1, 1, 1, factor);
        } else {
            state.color.alphaMultiplier *= factor;
        }
    }

    public function setBlendMode (blendMode :BlendMode)
    {
        var state = getTopState();
        switch (blendMode) {
            case Normal: state.blendMode = null;
            case Add: state.blendMode = flash.display.BlendMode.ADD;
			default: throw "Not Implemented";
        };
    }

    private function blit (texture :Texture, destX :Float, destY :Float, sourceRect :Rectangle)
    {
        flushGraphics();
		
        var flashTexture = Lib.as(texture, BitmapTexture);
        var state = getTopState();
        var matrix = state.matrix;

        // Use the faster copyPixels() if possible
        if (matrix.a == 1 && matrix.b == 0 && matrix.c == 0 && matrix.d == 1
                && state.color == null && state.blendMode == null) {

            if (sourceRect == null) {
                sourceRect = _scratchRect;
                sourceRect.x = 0;
                sourceRect.y = 0;
                sourceRect.width = flashTexture.width;
                sourceRect.height = flashTexture.height;
            }
            _scratchPoint.x = matrix.tx + destX;
            _scratchPoint.y = matrix.ty + destY;
			
            _buffer.copyPixels(flashTexture.image, sourceRect, _scratchPoint, null, null, true);
        } else {
			_scratchMatrix.copyFrom(matrix);
            if (destX != 0 || destY != 0) { 
                //TODO: Optimize?
                translate(destX, destY);
            }
            if (sourceRect != null) {
                // BitmapData.draw() doesn't support a source rect, so we have to use a temp
                // (contrary to the docs, clipRect is relative to the target, not the source)
                if (sourceRect.width > 0 && sourceRect.height > 0) {
                    var scratch = new BitmapData(
                        Std.int(sourceRect.width), Std.int(sourceRect.height), true, 0);
                    _scratchPoint.x = 0;
                    _scratchPoint.y = 0;
                    scratch.copyPixels(flashTexture.root.image, sourceRect, _scratchPoint, null, null, true);
					
                    _buffer.draw(scratch, matrix, state.color, state.blendMode, null, true);
                    scratch.dispose();
                }
            } else {
               _buffer.draw(flashTexture.image, matrix, state.color, state.blendMode, null, true);
            }
			state.matrix.copyFrom(_scratchMatrix);
        }
    }

    inline private function getTopState () :DrawingState
    {
        return _stack.head.elt;
    }

    private function flushGraphics ()
    {
        // If we're in vector graphics mode, push it out to the screen buffer
        if (_graphics != null) {
            var state = getTopState();
            _buffer.draw(_shape, state.matrix, state.color, state.blendMode, null, true);
            _graphics.clear();
            _graphics = null;
        }
    }

    inline private function beginGraphics ()
    {
        if (_graphics == null) {
            _graphics = _shape.graphics;
        }
    }

    private var _stack :GenericStack<DrawingState>;
    private var _buffer :BitmapData;

    // The shape used for all rendering that can't be done with a BitmapData
    private var _shape :Shape;

    // The vector graphic commands pending drawing, or null if we're not in vector graphics mode
    private var _graphics :Graphics;

    // A 1x1 BitmapData used to optimize fillRect's worst-case
    private var _pixel :BitmapData;

    // Reusable instances to avoid tons of allocation
    private var _scratchPoint :Point;
    private var _scratchRect :Rectangle;
    private var _scratchMatrix :Matrix;
}

private class DrawingState
{
    public var matrix :Matrix;
    public var color :ColorTransform;
    public var blendMode :flash.display.BlendMode;

    public function new () { }
}
