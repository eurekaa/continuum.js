# Continuum.js

continuum.js is a fork of [Continuation.js](https://github.com/BYVoid/continuation).
It is a compiler for [Continuation-Passing Style](http://en.wikipedia.org/wiki/Continuation-passing_style) transformation
which lets you write asynchronous code in a synchronous way.


```javascript
sum 1, 1, _(tot)
    console.log tot

    sum tot, 1, _(tot)
    console.log tot
```

instead of

```javascript
    // javascript compiled

    sum(a, b, function(tot){
        console.log(tot);

        sum(tot, 1, function(tot){
            console.log(tot);
        });
    });
```


I'm going to adapt this compiler to my needs.


1. added shortcuts for coffee-script developers:

    cont(err, value) or __(err, value) for coffee-scripters.

    obtain(value) or _(value) for coffee-scripters.

    parallel keyword remains the same for the moment.


2. fixed problems with ignored parameters.


3. I'll try to change some syntax too.