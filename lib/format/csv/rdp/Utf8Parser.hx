package format.csv.rdp;

import haxe.Utf8;
import haxe.io.*;

class Utf8Parser extends Parser {
    override function substring(str, pos, ?len)
    {
        if (len == null)
            len = Utf8.length(str);
        return Utf8.sub(str, pos, len);
    }

    override function stringLength(str):Int
    {
        return Utf8.length(str);
    }

    function validUtf8(bytes:Bytes, pos, len)
    {
        // adapted from neko/libs/std/utf8.c@utf8_validate
        while (pos < len) {
            var e = pos;
            var c = bytes.get(pos++);
            if (c < 0x7f) {
                // ok
            } else if (c < 0xc0) {
                return e;
            } else if (c < 0xe0) {
                if (pos >= len || bytes.get(pos++) & 0x80 != 0x80)
                    return e;
            } else if (c < 0xf0) {
                if (pos >= len || bytes.get(pos++) & 0x80 != 0x80)
                    return e;
                if (pos >= len || bytes.get(pos++) & 0x80 != 0x80)
                    return e;
            } else {
                if (pos >= len || bytes.get(pos++) & 0x80 != 0x80)
                    return e;
                if (pos >= len || bytes.get(pos++) & 0x80 != 0x80)
                    return e;
                if (pos >= len || bytes.get(pos++) & 0x80!= 0x80)
                    return e;
            }
        }
        return -1;
    }

    override function readMore(n:Int)
    {
        if (inp == null)
            return null;

        try {
            var bytes = Bytes.alloc(n + 4);
            var got = inp.readBytes(bytes, 0, n);

            var e = validUtf8(bytes, 0, got);
            for (i in 0...3) {
                if (e == -1)  // ok
                    break;
                got += inp.readBytes(bytes, got, 1);
                e = validUtf8(bytes, e, got);
            }
            if (e != -1)
                throw 'Invalid Utf8 stream: [...]${bytes.getString(e, got - 3)}';

            return bytes.getString(0, got);
        } catch (e:Eof) {
            return null;
        }
    }
}

