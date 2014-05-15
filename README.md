# Neck

[![Build Status](https://travis-ci.org/smalluban/neck.svg)](https://travis-ci.org/smalluban/neck) [![Coverage Status](https://coveralls.io/repos/smalluban/neck/badge.png?branch=master)](https://coveralls.io/r/smalluban/neck?branch=master)

Neck is a library that adds number of features to Backbone.js:

* Live data binding between view and controller
* HTML node attributes way to create logic in views
* Easy and automatic connection between controller and view
* Working with any template engine with data binding
* Two-way routing (by refrencing and url based) to nested views
* Simple dependeny injection module working with CommonJS out of the box

Neck is highly inspired (in convension and code) by frameworks 
[Angular](http://angularjs.org/) and [Batman](http://batmanjs.org/). 
If you already know one of them, it will be easy to you to start working with Neck.

## Setup

```shell
bower install --save neck
```

Library depends on [Backbone.js](http://backbonejs.org/) and [Underscore.js](http://underscorejs.org/).
They have to be included before Neck. 

```html
<script src="/path/to/backbone.js"></script>
<script src="/path/to/underscore.js"></script>
<script src="/path/to/neck.js"></script>
```

If you use [Brunch](http://brunch.io/) it will include scripts automaticly in proper order to your vendor scripts file (It reads `bower.json` file).

## Documentation

Will be very soon here.

## Neck for Spine

Neck for Spine moved to [neck-spine](https://github.com/smalluban/neck-spine) repository. 
After some problems with model sync with server I changed framework to Backbone.

## Contribution

Feel free to contribute project. For developing, clone project and run:

```
npm install && bower install
```

Use `npm start` and go to your browser `http://localhost:3333/test/` for checking tests. 

## Pull requests

Write some changes, update tests and do pull request to this repository. Please provide 
proper prefix to your commits: `BUG-FIX`, `TEST`, `DOCS`, `REFACTOR` and `NEW-FUNC`. It will be easier
to create changelog reading meaningful commits.

## License

Neck is released under the [MIT License](https://raw.github.com/smalluban/neck/master/LICENSE)

