var pwPipe = function (transform) { return transform(this); };

Object.defineProperty(Object.prototype, 'pwPipe', {
  value: pwPipe
});

Object.defineProperty(Function.prototype, 'pwPipe', {
  value: pwPipe
});

if (!String.prototype.includes) {
  String.prototype.includes = function(search, start) {
    'use strict';
    if (typeof start !== 'number') {
      start = 0;
    }

    if (start + search.length > this.length) {
      return false;
    } else {
      return this.indexOf(search, start) !== -1;
    }
  };
}
